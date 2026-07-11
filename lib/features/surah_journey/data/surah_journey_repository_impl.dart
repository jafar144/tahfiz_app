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
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
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
  /// `surah_journey_progress/{uid}` →
  /// `{ xp: 120, surahs: { "92": { sections: {...}, exam: {...} }, ... } }`.
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
      final data = snap.data() ?? const <String, dynamic>{};
      final raw = (data['surahs'] as Map<String, dynamic>?) ?? {};
      final surahs = <int, SurahProgress>{};
      raw.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map<String, dynamic>) {
          surahs[id] = SurahProgress.fromMap(value);
        }
      });
      return Right(
        JourneyProgress(surahs: surahs, xp: (data['xp'] as num?)?.toInt() ?? 0),
      );
    } catch (e) {
      return Left(ServerFailure('Gagal memuat progres: $e'));
    }
  }

  /// Ambil progres lama satu surah (best-effort; offline → progres kosong).
  Future<SurahProgress> _readSurahProgress(
    DocumentReference<Map<String, dynamic>> doc,
    int surahId,
  ) async {
    try {
      final snap = await doc.get().timeout(const Duration(seconds: 5));
      final raw = (snap.data()?['surahs'] as Map<String, dynamic>?) ?? {};
      final m = raw['$surahId'];
      if (m is Map<String, dynamic>) return SurahProgress.fromMap(m);
    } catch (_) {
      // Offline / lambat → lanjut dengan progres kosong (merge tetap aman).
    }
    return SurahProgress.empty;
  }

  /// Tulis progres satu surah + tambah XP; tulisan diantre Firestore saat
  /// offline — anggap tersimpan bila timeout.
  Future<void> _writeSurahProgress(
    DocumentReference<Map<String, dynamic>> doc,
    int surahId,
    SurahProgress updated,
    int xpDelta,
  ) async {
    try {
      await doc
          .set({
            if (xpDelta > 0) 'xp': FieldValue.increment(xpDelta),
            'surahs': {'$surahId': updated.toMap()},
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // Tersimpan di antrean lokal & tersinkron otomatis saat online.
    }
  }

  @override
  Future<Either<Failure, SurahProgress>> saveSectionResult({
    required int surahId,
    required String sectionId,
    required int correct,
    required bool passed,
    required int xpDelta,
  }) async {
    try {
      final doc = _myDoc();
      if (doc == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }
      final prev = await _readSurahProgress(doc, surahId);
      final prevSection = prev.of(sectionId);
      final updated = prev.withSection(
        sectionId,
        SectionProgress(
          passed: prevSection.passed || passed,
          bestCorrect: max(prevSection.bestCorrect, correct),
        ),
      );
      await _writeSurahProgress(doc, surahId, updated, xpDelta);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan hasil test: $e'));
    }
  }

  @override
  Future<Either<Failure, SurahProgress>> saveExamResult({
    required int surahId,
    required int score,
    required bool passed,
    required int xpDelta,
  }) async {
    try {
      final doc = _myDoc();
      if (doc == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }
      final prev = await _readSurahProgress(doc, surahId);
      final updated = prev.withExam(passed: passed, score: score);
      await _writeSurahProgress(doc, surahId, updated, xpDelta);
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
  Future<Either<Failure, List<LessonQuestion>>> generateSectionTest(
    SurahLesson lesson,
    LessonSection section,
  ) {
    return _generate(
      lesson: lesson,
      questionCount: section.test.questionCount,
      voiceContinueCount: section.test.voiceContinueCount,
      voiceLastAyahCount: section.test.voiceLastAyahCount,
      choicePool: (ayat, rng) => [
        ...section.test.bank,
        if (section.test.useVocabQuestions)
          ..._vocabQuestions(section.vocabItems, ayat, rng),
      ],
      matchBuilder: section.test.useVocabQuestions
          ? (rng) => _vocabMatchQuestion(section.vocabItems, rng)
          : null,
    );
  }

  @override
  Future<Either<Failure, List<LessonQuestion>>> generateExam(
    SurahLesson lesson,
  ) {
    return _generate(
      lesson: lesson,
      questionCount: LessonConfig.examQuestionCount,
      voiceContinueCount: LessonConfig.examVoiceContinueCount,
      voiceLastAyahCount: LessonConfig.examVoiceLastAyahCount,
      // Gabungan bank tertulis semua bagian + soal kosa kata seluruh surah.
      choicePool: (ayat, rng) => [
        for (final s in lesson.sections) ...s.test.bank,
        ..._vocabQuestions(
          [for (final s in lesson.sections) ...s.vocabItems],
          ayat,
          rng,
        ),
      ],
      matchBuilder: (rng) => _vocabMatchQuestion([
        for (final section in lesson.sections) ...section.vocabItems,
      ], rng),
    );
  }

  /// Mesin penyusun soal: soal suara (sambung ayat + ayat terakhir) lalu
  /// slot sisanya diisi soal pilihan dari [choicePool] yang diundi.
  Future<Either<Failure, List<LessonQuestion>>> _generate({
    required SurahLesson lesson,
    required int questionCount,
    required int voiceContinueCount,
    required int voiceLastAyahCount,
    required List<FactQuestion> Function(List<Ayah> ayat, Random rng)
    choicePool,
    LessonQuestion? Function(Random rng)? matchBuilder,
  }) async {
    try {
      final ayatRes = await getSurahAyat(lesson.surahId);
      Failure? loadFail;
      var ayat = const <Ayah>[];
      ayatRes.fold(ifLeft: (f) => loadFail = f, ifRight: (a) => ayat = a);
      final fail = loadFail;
      if (fail != null) return Left(fail);
      final needVoice = voiceContinueCount + voiceLastAyahCount > 0;
      if (needVoice && ayat.length < 3) {
        return const Left(UnknownFailure('Surah terlalu pendek untuk test.'));
      }

      final rng = Random();
      final questions = <LessonQuestion>[];
      final match = matchBuilder?.call(rng);

      // ── Soal SUARA ──────────────────────────────────────────────────────
      // 1) "Baca ayat terakhir": ayat tampil diundi dari selain ayat terakhir.
      final usedPromptNumbers = <int>{};
      if (voiceLastAyahCount > 0) {
        final last = ayat.last;
        final lastPromptPool = ayat.sublist(0, ayat.length - 1);
        for (var i = 0; i < voiceLastAyahCount; i++) {
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
      }

      // 2) "Sambung ayat": prompt diundi dari ayat yang punya lanjutan.
      final voiceTarget = questions.length + voiceContinueCount;
      final candidates = List<int>.generate(ayat.length - 1, (i) => i)
        ..shuffle(rng);
      for (final i in candidates) {
        if (questions.length >= voiceTarget) break;
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

      // ── Soal PILIHAN ─────────────────────────────────────────────────────
      // Mengisi sisa slot hingga [questionCount]; bila surah terlalu pendek
      // untuk porsi soal suara, porsi pilihan otomatis bertambah.
      final pool = choicePool(ayat, rng)..shuffle(rng);
      for (final fact in pool) {
        if (questions.length >= questionCount) break;
        questions.add(LessonQuestion.choice(fact));
      }

      if (match != null) {
        final matchIndex = questions.indexWhere(
          (question) => !question.isVoice,
        );
        if (matchIndex >= 0) questions[matchIndex] = match;
      }

      if (questions.length < questionCount) {
        return const Left(
          UnknownFailure('Data tidak cukup untuk menyusun soal test.'),
        );
      }

      questions.shuffle(rng);
      return Right(questions.take(questionCount).toList());
    } catch (e) {
      return Left(UnknownFailure('Gagal menyusun soal test: $e'));
    }
  }

  /// Susun soal pilihan dari daftar kosa kata: bergantian menanyakan ARTI
  /// kata yang disorot pada ayatnya, dan sebaliknya (arti → kata Arab).
  /// Opsi pengecoh diambil dari kosa kata lain di surah yang sama.
  List<FactQuestion> _vocabQuestions(
    List<VocabItem> items,
    List<Ayah> ayat,
    Random rng,
  ) {
    if (items.length < 4) return const [];
    final textOf = {for (final a in ayat) a.number: a.text};
    final shuffled = [...items]..shuffle(rng);
    final questions = <FactQuestion>[];

    for (var i = 0; i < shuffled.length; i++) {
      final item = shuffled[i];
      final others = [...shuffled]..remove(item);
      others.shuffle(rng);
      final askMeaning = i.isEven;

      // Opsi: jawaban benar + 3 pengecoh, lalu diacak posisinya.
      final options = askMeaning
          ? [item.meaning, ...others.take(3).map((o) => o.meaning)]
          : [item.word, ...others.take(3).map((o) => o.word)];
      final correct = options.first;
      options.shuffle(rng);

      questions.add(
        FactQuestion(
          question: askMeaning
              ? 'Apa arti kata yang disorot pada ayat berikut?'
              : 'Manakah kata yang artinya "${item.meaning}"?',
          options: options,
          correctIndex: options.indexOf(correct),
          arabicText: askMeaning ? textOf[item.ayahNumber] : null,
          highlightWord: askMeaning ? item.word : null,
          arabicOptions: !askMeaning,
        ),
      );
    }
    return questions;
  }

  LessonQuestion? _vocabMatchQuestion(List<VocabItem> items, Random rng) {
    if (items.length < 4) return null;
    final selected = [...items]..shuffle(rng);
    return LessonQuestion.match(
      VocabMatchQuestion(
        pairs: [
          for (final item in selected.take(4))
            VocabMatchPair(arabic: item.word, meaning: item.meaning),
        ],
      ),
    );
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
