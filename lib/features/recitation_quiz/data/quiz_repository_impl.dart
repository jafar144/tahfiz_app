import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dart_either/dart_either.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/data/quran_local_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_energy_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuranLocalDataSource local;
  final RecitationRepository recitation;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final QuizEnergyRemoteDataSource energyRemote;

  QuizRepositoryImpl({
    required this.local,
    required this.recitation,
    required this.firestore,
    required this.auth,
    required this.energyRemote,
  });

  /// Rentang surah [dari, sampai] tiap juz yang didukung.
  static const Map<int, List<int>> _juzSurahRange = {
    29: [67, 77], // Al-Mulk .. Al-Mursalat
    30: [78, 114], // An-Naba' .. An-Nas
  };

  static const String _collection = 'recitation_quiz_attempts';

  /// Panjang jawaban maksimum (ayat) per soal.
  static const int _maxAnswerLen = 3;

  @override
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count = 10,
    required QuizSettings settings,
  }) async {
    try {
      final juzList =
          settings.sortedJuz.where(_juzSurahRange.containsKey).toList();
      if (juzList.isEmpty) {
        return const Left(UnknownFailure('Pilih minimal satu juz.'));
      }

      // Susun pool ayat sesuai juz terpilih, urut mushaf.
      final pool = <Ayah>[];
      for (final j in juzList) {
        final range = _juzSurahRange[j]!;
        pool.addAll(await local.getAyatForSurahRange(
          fromSurah: range[0],
          toSurah: range[1],
        ));
      }
      if (pool.length < 2) {
        return const Left(UnknownFailure('Data juz terpilih tidak lengkap.'));
      }

      // Basmalah (dari Al-Fatihah 1:1) untuk transisi antar surah.
      final basmalahList = await local.getAyatRange(surahId: 1, from: 1, to: 1);
      final basmalahText =
          basmalahList.isNotEmpty ? basmalahList.first.text : '';

      // Kandidat prompt = indeks ayat yang punya minimal 1 ayat lanjutan valid.
      // Bila sambungan antar surah dimatikan, lanjutan wajib di surah yang sama
      // (ayat terakhir tiap surah tak jadi kandidat).
      final candidates = <int>[];
      for (var i = 0; i < pool.length - 1; i++) {
        final next = pool[i + 1];
        if (!settings.crossSurah && next.surahId != pool[i].surahId) continue;
        candidates.add(i);
      }
      if (candidates.isEmpty) {
        return const Left(
            UnknownFailure('Data tidak cukup untuk menyusun soal.'));
      }

      final rng = Random();
      candidates.shuffle(rng);
      final chosen = candidates.take(min(count, candidates.length));

      final questions = <QuizQuestion>[];
      for (final i in chosen) {
        final prompt = pool[i];
        final maxLen = _availableAnswerLen(pool, i, settings.crossSurah);
        final len = 1 + rng.nextInt(maxLen); // 1.._maxAnswerLen (dibatasi)

        final answer = <Ayah>[];
        for (var k = 1; k <= len; k++) {
          final a = pool[i + k];
          if (a.number == 1 && basmalahText.isNotEmpty) {
            answer.add(Ayah(
              surahId: a.surahId,
              number: 0, // penanda basmalah (bukan ayat bernomor)
              text: basmalahText,
              page: a.page,
              surahName: a.surahName,
            ));
          }
          answer.add(a);
        }
        questions.add(QuizQuestion(prompt: prompt, answer: answer));
      }

      questions.shuffle(rng);
      return Right(questions);
    } catch (e) {
      return Left(UnknownFailure('Gagal menyusun soal kuis: $e'));
    }
  }

  /// Jumlah ayat lanjutan yang tersedia dari indeks [i] (1.._maxAnswerLen).
  /// Bila [crossSurah] false, berhenti di batas surah prompt.
  int _availableAnswerLen(List<Ayah> pool, int i, bool crossSurah) {
    final promptSurah = pool[i].surahId;
    var len = 0;
    for (var k = 1; k <= _maxAnswerLen && i + k < pool.length; k++) {
      if (!crossSurah && pool[i + k].surahId != promptSurah) break;
      len++;
    }
    return len; // >= 1 karena i selalu diambil dari kandidat valid
  }

  @override
  Future<Either<Failure, RecitationResult>> checkAnswer({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  }) {
    return recitation.checkRecitation(
      targetAyat: answerAyat,
      audioFilePath: audioFilePath,
      mimeType: mimeType,
    );
  }

  @override
  Future<Either<Failure, void>> saveAttempt({
    required int totalScore,
    required List<int> questionScores,
    required List<int> juz,
    required bool crossSurah,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }

      var name = user.displayName ?? '';
      var role = '';
      try {
        final doc =
            await firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (data != null) {
          name = (data['name'] as String?)?.trim().isNotEmpty == true
              ? data['name'] as String
              : name;
          role = (data['role'] as String?) ?? '';
        }
      } catch (_) {
        // Nama/role opsional; simpan tetap lanjut walau gagal ambil profil.
      }

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final dateKey = '${now.year}-${two(now.month)}-${two(now.day)}';

      await firestore.collection(_collection).add({
        'user_id': user.uid,
        'user_name': name,
        'role': role,
        'juz': juz,
        'cross_surah': crossSurah,
        'total_score': totalScore,
        'question_scores': questionScores,
        'date_key': dateKey,
        'created_at': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan hasil kuis: $e'));
    }
  }

  // Energi dihitung SISI SERVER (Cloud Function) memakai waktu server, sehingga
  // tidak bisa diakali dengan mengubah jam perangkat. Repo hanya mendelegasikan.

  @override
  Future<Either<Failure, QuizEnergy>> getEnergy() async {
    try {
      return Right(await energyRemote.getEnergy());
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat energi.'));
    } catch (e) {
      return Left(ServerFailure('Gagal memuat energi: $e'));
    }
  }

  @override
  Future<Either<Failure, QuizEnergy>> startSession() async {
    try {
      return Right(await energyRemote.startSession());
    } on FirebaseFunctionsException catch (e) {
      return Left(QuizBlockedFailure(
        _reasonOf(e),
        e.message ?? 'Kuis sedang tidak bisa dimulai.',
      ));
    } catch (e) {
      return Left(QuizBlockedFailure(
        QuizBlockReason.unknown,
        'Gagal memulai sesi: $e',
      ));
    }
  }

  @override
  Future<void> heartbeat() => energyRemote.heartbeat();

  @override
  Future<void> endSession() => energyRemote.endSession();

  /// Petakan error callable → alasan blokir yang dipahami UI.
  QuizBlockReason _reasonOf(FirebaseFunctionsException e) {
    final details = e.details;
    final reason = details is Map ? details['reason'] : null;
    switch (reason) {
      case 'busy':
        return QuizBlockReason.busy;
      case 'whisper':
        return QuizBlockReason.whisperLimit;
      case 'no_energy':
        return QuizBlockReason.noEnergy;
    }
    // Fallback berdasarkan kode HttpsError bila details tak ada.
    switch (e.code) {
      case 'resource-exhausted':
        return QuizBlockReason.whisperLimit;
      case 'aborted':
        return QuizBlockReason.busy;
      case 'failed-precondition':
        return QuizBlockReason.noEnergy;
    }
    return QuizBlockReason.unknown;
  }
}
