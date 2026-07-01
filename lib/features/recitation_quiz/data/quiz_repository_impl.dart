import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_either/dart_either.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/data/quran_local_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuranLocalDataSource local;
  final RecitationRepository recitation;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  QuizRepositoryImpl({
    required this.local,
    required this.recitation,
    required this.firestore,
    required this.auth,
  });

  /// Batas surah Juz 30 (An-Naba' 78 .. An-Nas 114).
  static const int _juz30From = 78;
  static const int _juz30To = 114;

  static const String _collection = 'recitation_quiz_attempts';

  @override
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count = 10,
  }) async {
    try {
      final pool = await local.getAyatForSurahRange(
        fromSurah: _juz30From,
        toSurah: _juz30To,
      );
      // Kandidat prompt = semua ayat yang punya ayat sesudahnya di pool.
      // Ayat terakhir (An-Nas ayat terakhir) otomatis tak terpilih karena
      // tidak punya lanjutan.
      final maxPrompt = pool.length - 1; // indeks eksklusif untuk prompt
      if (maxPrompt < 1) {
        return const Left(UnknownFailure('Data Juz 30 tidak lengkap.'));
      }

      // Basmalah (dari Al-Fatihah 1:1) untuk transisi antar surah.
      final basmalahList = await local.getAyatRange(surahId: 1, from: 1, to: 1);
      final basmalahText =
          basmalahList.isNotEmpty ? basmalahList.first.text : '';

      final rng = Random();
      final take = min(count, maxPrompt);
      final chosen = <int>{};
      while (chosen.length < take) {
        chosen.add(rng.nextInt(maxPrompt)); // 0..maxPrompt-1
      }

      final questions = <QuizQuestion>[];
      for (final i in chosen) {
        final prompt = pool[i];
        final next = pool[i + 1];
        final answer = <Ayah>[];
        if (next.number == 1 && basmalahText.isNotEmpty) {
          answer.add(Ayah(
            surahId: next.surahId,
            number: 0, // penanda basmalah (bukan ayat bernomor)
            text: basmalahText,
            page: next.page,
            surahName: next.surahName,
          ));
        }
        answer.add(next);
        questions.add(QuizQuestion(prompt: prompt, answer: answer));
      }

      questions.shuffle(rng);
      return Right(questions);
    } catch (e) {
      return Left(UnknownFailure('Gagal menyusun soal kuis: $e'));
    }
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
        'juz': 30,
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
}
