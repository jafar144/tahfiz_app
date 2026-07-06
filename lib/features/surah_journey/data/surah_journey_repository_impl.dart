import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_either/dart_either.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/data/quran_local_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/repositories/surah_journey_repository.dart';

class SurahJourneyRepositoryImpl implements SurahJourneyRepository {
  final QuranLocalDataSource local;
  final RecitationRepository recitation;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SurahJourneyRepositoryImpl({
    required this.local,
    required this.recitation,
    required this.firestore,
    required this.auth,
  });

  /// Satu dokumen progres per pengguna:
  /// `surah_journey_progress/{uid}` → `{ surahs: { "92": {...}, ... } }`.
  static const String _collection = 'surah_journey_progress';

  DocumentReference<Map<String, dynamic>>? _myDoc() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return firestore.collection(_collection).doc(uid);
  }

  @override
  Future<Either<Failure, JourneyProgress>> getProgress() async {
    try {
      final doc = _myDoc();
      if (doc == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }
      final snap = await doc.get();
      final raw = (snap.data()?['surahs'] as Map<String, dynamic>?) ?? {};
      final surahs = <int, SurahProgress>{};
      raw.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map<String, dynamic>) {
          surahs[id] = SurahProgress.fromMap(value);
        }
      });
      return Right(JourneyProgress(surahs: surahs));
    } catch (e) {
      return Left(ServerFailure('Gagal memuat progres: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markLearned(int surahId) async {
    try {
      final doc = _myDoc();
      if (doc == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }
      // Saat offline Firestore mengantre tulisan di cache — jangan gantung UI.
      unawaited(
        doc.set({
          'surahs': {
            '$surahId': {'learned': true},
          },
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan progres belajar: $e'));
    }
  }

  @override
  Future<Either<Failure, SurahProgress>> saveTestResult({
    required int surahId,
    required int score,
  }) async {
    try {
      final doc = _myDoc();
      if (doc == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }

      // Ambil progres lama (best-effort) untuk menghitung best score baru.
      SurahProgress prev = SurahProgress.empty;
      try {
        final snap = await doc.get().timeout(const Duration(seconds: 5));
        final raw = (snap.data()?['surahs'] as Map<String, dynamic>?) ?? {};
        final m = raw['$surahId'];
        if (m is Map<String, dynamic>) prev = SurahProgress.fromMap(m);
      } catch (_) {
        // Offline / lambat → lanjut dengan progres kosong (merge tetap aman).
      }

      final updated = prev.copyWith(
        learned: true,
        bestScore: max(prev.bestScore, score),
        completed: prev.completed || score >= LessonConfig.passScore,
      );

      // Tulisan diantre Firestore saat offline; anggap tersimpan bila timeout.
      try {
        await doc
            .set({
              'surahs': {
                '$surahId': {
                  ...updated.toMap(),
                  'last_score': score,
                  'updated_at': FieldValue.serverTimestamp(),
                },
              },
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 6));
      } on TimeoutException {
        // Tersimpan di antrean lokal & tersinkron otomatis saat online.
      }

      return Right(updated);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan hasil ujian: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> getSurahAyat(int surahId) async {
    try {
      final ayat = await local.getAyatRange(surahId: surahId, from: 1, to: 999);
      if (ayat.isEmpty) {
        return const Left(UnknownFailure('Teks surah tidak ditemukan.'));
      }
      return Right(ayat);
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat teks surah: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LessonQuestion>>> generateTest(
    SurahLesson lesson,
  ) async {
    try {
      final ayatRes = await getSurahAyat(lesson.surahId);
      Failure? loadFail;
      var ayat = const <Ayah>[];
      ayatRes.fold(ifLeft: (f) => loadFail = f, ifRight: (a) => ayat = a);
      final fail = loadFail;
      if (fail != null) return Left(fail);
      if (ayat.length < 3) {
        return const Left(UnknownFailure('Surah terlalu pendek untuk ujian.'));
      }

      final rng = Random();
      final questions = <LessonQuestion>[];

      // ── Soal SUARA ────────────────────────────────────────────────────────
      // 1) "Baca ayat terakhir": ayat tampil diundi dari selain ayat terakhir.
      final last = ayat.last;
      final lastPromptPool = ayat.sublist(0, ayat.length - 1);
      final usedPromptNumbers = <int>{};
      for (var i = 0; i < LessonConfig.voiceLastAyahCount; i++) {
        final prompt = lastPromptPool[rng.nextInt(lastPromptPool.length)];
        if (!usedPromptNumbers.add(prompt.number)) continue;
        questions.add(
          LessonQuestion.voice(
            type: LessonTaskType.voiceLastAyah,
            prompt: prompt,
            answer: [last],
          ),
        );
      }

      // 2) "Sambung ayat": prompt diundi dari ayat yang punya lanjutan.
      final candidates = List<int>.generate(ayat.length - 1, (i) => i)
        ..shuffle(rng);
      for (final i in candidates) {
        if (questions.length >= LessonConfig.voiceQuestionCount) break;
        final prompt = ayat[i];
        if (!usedPromptNumbers.add(prompt.number)) continue;
        final available = min(
          LessonConfig.maxContinueAyah,
          ayat.length - 1 - i,
        );
        final len = 1 + rng.nextInt(available);
        questions.add(
          LessonQuestion.voice(
            type: LessonTaskType.voiceContinue,
            prompt: prompt,
            answer: [for (var k = 1; k <= len; k++) ayat[i + k]],
          ),
        );
      }

      // ── Soal PILIHAN materi ───────────────────────────────────────────────
      // Mengisi sisa slot hingga [LessonConfig.questionCount]; bila surah
      // terlalu pendek untuk 5 soal suara, porsi pilihan otomatis bertambah.
      final bank = [...lesson.questionBank]..shuffle(rng);
      for (final fact in bank) {
        if (questions.length >= LessonConfig.questionCount) break;
        questions.add(LessonQuestion.choice(fact));
      }

      if (questions.length < 3) {
        return const Left(
          UnknownFailure('Data tidak cukup untuk menyusun ujian.'),
        );
      }

      questions.shuffle(rng);
      return Right(questions.take(LessonConfig.questionCount).toList());
    } catch (e) {
      return Left(UnknownFailure('Gagal menyusun soal ujian: $e'));
    }
  }

  @override
  Future<Either<Failure, RecitationResult>> checkRecitation({
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
}
