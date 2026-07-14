import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_session_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/repositories/surah_journey_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/vocab_learning_rules.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';

/// Cubit sesi SATU surah Petualangan Surah: daftar bagian → belajar per
/// bagian → test kecil → (semua lulus) ujian akhir → hasil + XP.
///
/// Energi: tiap percobaan test yang BELUM pernah lulus memotong 1 energi
/// (lewat `startQuizSession` di server, seperti Latihan kuis); setelah pernah
/// lulus, mengulang gratis. Admin & master switch mati → tanpa energi.
class SurahLessonCubit extends Cubit<SurahLessonState> {
  final SurahJourneyRepository repository;
  final QuizRepository quizRepository;

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;

  /// Penjaga auto-lanjut soal pilihan: hanya berlaku untuk soal yang sama.
  int _feedbackTicket = 0;

  /// Diisi saat init; admin tidak terkena potongan energi.
  bool _isAdmin = false;

  /// Status lulus target test SEBELUM percobaan berjalan (penentu XP &
  /// gratis/berbayarnya percobaan berikut pada layar hasil).
  bool _passedBefore = false;

  SurahLessonCubit(this.repository, this.quizRepository, SurahLesson lesson)
    : super(SurahLessonState(lesson: lesson));

  /// Muat teks surah + progres surah ini + status admin. Selesai (sukses
  /// ataupun gagal) → [SurahLessonState.initialized] true agar halaman keluar
  /// dari loading dedicated dan menampilkan daftar bagian.
  Future<void> init() async {
    final ayatRes = await repository.getSurahAyat(state.lesson.surahId);
    if (isClosed) return;
    ayatRes.fold(
      ifLeft: (f) => emit(state.copyWith(errorMessage: f.message)),
      ifRight: (ayat) => emit(state.copyWith(surahAyat: ayat)),
    );

    final progressRes = await repository.getProgress();
    if (isClosed) return;
    progressRes.fold(
      ifLeft: (f) => emit(state.copyWith(errorMessage: f.message)),
      ifRight: (p) =>
          emit(state.copyWith(progress: p.of(state.lesson.surahId))),
    );

    _isAdmin = await quizRepository.isCurrentUserAdmin();
    if (isClosed) return;
    emit(state.copyWith(initialized: true));
  }

  // ─────────────────────────────────────────────────────────── Navigasi ──

  /// Buka halaman belajar sebuah bagian.
  void openSection(LessonSection section) {
    emit(
      state.copyWith(
        status: LessonStatus.learning,
        activeSection: section,
        clearActiveVocabPhase: true,
        clearError: true,
      ),
    );
  }

  /// Kembali ke daftar bagian (dari belajar/test/hasil).
  void backToOverview() {
    _feedbackTicket++;
    emit(
      state.copyWith(
        status: LessonStatus.overview,
        clearActiveSection: true,
        clearActiveVocabPhase: true,
        phase: LessonPhase.idle,
        clearVoiceResult: true,
        clearChoicePick: true,
        choiceLocked: false,
        vocabHintVisible: false,
        clearXpGained: true,
        clearError: true,
      ),
    );
  }

  /// Kembali ke halaman belajar bagian aktif (dari hasil yang gagal).
  void backToLearning() {
    final section = state.activeSection;
    if (section == null) {
      backToOverview();
      return;
    }
    _feedbackTicket++;
    emit(
      state.copyWith(
        status: LessonStatus.learning,
        phase: LessonPhase.idle,
        clearVoiceResult: true,
        clearChoicePick: true,
        choiceLocked: false,
        vocabHintVisible: false,
        clearXpGained: true,
        clearError: true,
      ),
    );
  }

  /// Dari hasil lulus: langsung buka bagian berikutnya.
  void continueToSection(LessonSection section) => openSection(section);

  // ─────────────────────────────────────────────────────────────── Test ──

  /// Mulai test bagian yang sedang dipelajari.
  Future<void> startSectionTest() async {
    final section = state.activeSection;
    if (section == null) return;
    await _startTest(section: section, vocabPhase: state.activeVocabPhase);
  }

  /// Mulai salah satu kuis kosa kata langsung dari daftar tahap.
  Future<void> startVocabQuiz(
    LessonSection section,
    VocabLearningPhase phase,
  ) async {
    if (!state.sectionUnlocked(section)) return;
    final previous = phase.index - 1;
    if (previous >= 0 &&
        !state.vocabPhasePassed(section, VocabLearningPhase.values[previous])) {
      return;
    }
    await _startTest(section: section, vocabPhase: phase);
  }

  /// Mulai UJIAN AKHIR surah (dari daftar bagian; semua bagian harus lulus).
  Future<void> startExam() async {
    if (!state.examUnlocked) return;
    await _startTest(section: null, vocabPhase: null);
  }

  /// Ulangi test yang barusan selesai (soal diundi ulang; energi mengikuti
  /// status lulus TERBARU — sudah lulus → gratis).
  Future<void> retryTest() => _startTest(
    section: state.activeSection,
    vocabPhase: state.activeVocabPhase,
  );

  Future<void> _startTest({
    required LessonSection? section,
    required VocabLearningPhase? vocabPhase,
  }) async {
    emit(
      state.copyWith(
        status: LessonStatus.loading,
        activeSection: section,
        clearActiveSection: section == null,
        activeVocabPhase: vocabPhase,
        clearActiveVocabPhase: vocabPhase == null,
        clearError: true,
      ),
    );

    _passedBefore = section == null
        ? state.progress.examPassed
        : vocabPhase == null
        ? state.progress.of(section.id).passed
        : state.vocabPhasePassed(section, vocabPhase);

    // Potong energi di server bila belum pernah lulus (admin/master off skip).
    if (!_passedBefore && QuizSessionRules.enforceServerGate && !_isAdmin) {
      final energyRes = await quizRepository.startSession(
        mode: QuizMode.choice,
      );
      if (isClosed) return;
      String? blockMessage;
      energyRes.fold(
        ifLeft: (f) {
          blockMessage =
              f is QuizBlockedFailure && f.reason == QuizBlockReason.noEnergy
              ? 'Energimu habis! Tunggu pengisian energi dulu, ya.'
              : f.message;
        },
        ifRight: (_) {},
      );
      if (blockMessage != null) {
        emit(
          state.copyWith(
            status: section == null || vocabPhase != null
                ? LessonStatus.overview
                : LessonStatus.learning,
            errorMessage: blockMessage,
          ),
        );
        return;
      }
    }

    final res = section == null
        ? await repository.generateExam(state.lesson)
        : await repository.generateSectionTest(
            state.lesson,
            section,
            vocabPhase: vocabPhase,
          );
    if (isClosed) return;
    res.fold(
      ifLeft: (f) => emit(
        state.copyWith(
          status: section == null || vocabPhase != null
              ? LessonStatus.overview
              : LessonStatus.learning,
          errorMessage: f.message,
        ),
      ),
      ifRight: (questions) => emit(
        state.copyWith(
          status: LessonStatus.testing,
          questions: questions,
          currentIndex: 0,
          phase: LessonPhase.idle,
          clearVoiceResult: true,
          clearChoicePick: true,
          choiceLocked: false,
          answers: const [],
          vocabHintVisible: false,
          clearXpGained: true,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── Soal suara ──

  void showVocabHint() {
    if (state.isExam || state.currentQuestion?.isVocabRecall != true) return;
    emit(state.copyWith(vocabHintVisible: true));
  }

  Future<void> startRecording() async {
    final q = state.currentQuestion;
    if (q == null || !q.isVoice || state.phase != LessonPhase.idle) return;
    try {
      if (!await _recorder.hasPermission()) {
        emit(
          state.copyWith(
            errorMessage: 'Izin mikrofon ditolak. Aktifkan di pengaturan.',
          ),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/lesson_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recordPath = path;
      emit(state.copyWith(phase: LessonPhase.recording, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal memulai rekaman: $e'));
    }
  }

  /// Hentikan rekaman lalu periksa bacaan terhadap ayat jawaban.
  Future<void> stopAndCheck() async {
    final q = state.currentQuestion;
    if (q == null || state.phase != LessonPhase.recording) return;
    try {
      final stopped = await _recorder.stop();
      final path = stopped ?? _recordPath;
      if (path == null) {
        emit(
          state.copyWith(
            phase: LessonPhase.idle,
            errorMessage: 'Rekaman tidak tersimpan.',
          ),
        );
        return;
      }

      emit(state.copyWith(phase: LessonPhase.processing, clearError: true));
      final res = await repository.checkRecitation(
        answerAyat: q.answer,
        audioFilePath: path,
        mimeType: 'audio/mp4',
      );
      if (isClosed) return;
      res.fold(
        ifLeft: (f) => emit(
          state.copyWith(phase: LessonPhase.idle, errorMessage: f.message),
        ),
        ifRight: (result) {
          final correct =
              result.accuracyPercent >= LessonConfig.voicePassThreshold;
          emit(
            state.copyWith(
              phase: LessonPhase.revealed,
              voiceResult: result,
              answers: [...state.answers, correct],
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: LessonPhase.idle,
          errorMessage: 'Gagal memproses bacaan: $e',
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────── Soal pilihan ──

  /// Pilih opsi soal pilihan → kunci, nilai, lalu auto-lanjut.
  void pickChoice(int index) {
    final q = state.currentQuestion;
    if (q == null || q.isVoice || state.choiceLocked) return;

    final correct = index == q.fact!.correctIndex;
    emit(
      state.copyWith(
        choicePick: index,
        choiceLocked: true,
        answers: [...state.answers, correct],
      ),
    );

    final ticket = ++_feedbackTicket;
    Future.delayed(LessonConfig.choiceFeedbackDelay, () {
      if (isClosed || ticket != _feedbackTicket) return;
      next();
    });
  }

  /// Papan pencocokan sudah tuntas. Salah pilih tetap dapat diperbaiki di
  /// papan, tetapi hanya permainan tanpa salah yang bernilai benar penuh.
  void completeMatch(bool perfect) {
    final q = state.currentQuestion;
    if (q == null || !q.isMatch) return;
    emit(state.copyWith(answers: [...state.answers, perfect]));

    final ticket = ++_feedbackTicket;
    Future.delayed(LessonConfig.choiceFeedbackDelay, () {
      if (isClosed || ticket != _feedbackTicket) return;
      next();
    });
  }

  // ─────────────────────────────────────────────────────────── Lanjut soal ──

  /// Lanjut ke soal berikutnya, atau selesaikan test di soal terakhir.
  void next() {
    if (state.status != LessonStatus.testing) return;
    _feedbackTicket++;
    if (state.isLastQuestion) {
      _finish();
      return;
    }
    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
        phase: LessonPhase.idle,
        clearVoiceResult: true,
        clearChoicePick: true,
        choiceLocked: false,
        vocabHintVisible: false,
        clearError: true,
      ),
    );
  }

  Future<void> _finish() async {
    final section = state.activeSection;
    final vocabPhase = state.activeVocabPhase;
    final passed = state.passed;

    // XP: lulus pertama → hadiah penuh (+bonus sempurna khusus ujian akhir);
    // lulus lagi → XP kecil; gagal → 0.
    int xpDelta = 0;
    if (passed) {
      if (_passedBefore) {
        xpDelta = LessonConfig.xpRepeatPass;
      } else if (section != null) {
        xpDelta = vocabPhase == null
            ? section.test.xpReward
            : (section.test.xpReward / VocabLearningPhase.values.length)
                  .round();
      } else {
        xpDelta =
            LessonConfig.xpExamPass +
            (state.correctCount == state.questions.length
                ? LessonConfig.xpExamPerfectBonus
                : 0);
      }
    }

    emit(
      state.copyWith(
        status: LessonStatus.finished,
        saving: true,
        xpGained: xpDelta,
      ),
    );

    final res = section != null
        ? await repository.saveSectionResult(
            surahId: state.lesson.surahId,
            sectionId: vocabPhase == null
                ? section.id
                : VocabLearningRules.progressKey(section.id, vocabPhase),
            correct: state.correctCount,
            passed: passed,
            xpDelta: xpDelta,
          )
        : await repository.saveExamResult(
            surahId: state.lesson.surahId,
            score: state.score,
            passed: passed,
            xpDelta: xpDelta,
          );
    if (isClosed) return;
    res.fold(
      ifLeft: (f) => emit(
        state.copyWith(
          saving: false,
          errorMessage: 'Hasil gagal tersimpan: ${f.message}',
        ),
      ),
      ifRight: (progress) =>
          emit(state.copyWith(saving: false, progress: progress)),
    );
  }

  @override
  Future<void> close() async {
    await _recorder.dispose();
    return super.close();
  }
}
