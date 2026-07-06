import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/repositories/surah_journey_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';

/// Cubit sesi SATU surah Petualangan Surah: halaman belajar → ujian 10 soal
/// (suara + pilihan materi) → hasil & simpan progres.
class SurahLessonCubit extends Cubit<SurahLessonState> {
  final SurahJourneyRepository repository;

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;

  /// Penjaga auto-lanjut soal pilihan: hanya berlaku untuk soal yang sama.
  int _feedbackTicket = 0;

  SurahLessonCubit(this.repository, SurahLesson lesson)
    : super(SurahLessonState(lesson: lesson));

  /// Muat teks surah untuk halaman belajar.
  Future<void> init() async {
    final res = await repository.getSurahAyat(state.lesson.surahId);
    res.fold(
      ifLeft: (f) => emit(state.copyWith(errorMessage: f.message)),
      ifRight: (ayat) => emit(state.copyWith(surahAyat: ayat)),
    );
  }

  // ─────────────────────────────────────────────────────────────── Ujian ──

  /// Mulai ujian: tandai sudah belajar, susun soal, masuk layar ujian.
  Future<void> startTest() async {
    emit(state.copyWith(status: LessonStatus.loading, clearError: true));

    // Progres "sudah belajar" tak menghalangi ujian bila gagal tersimpan.
    unawaited(repository.markLearned(state.lesson.surahId));

    final res = await repository.generateTest(state.lesson);
    res.fold(
      ifLeft: (f) => emit(
        state.copyWith(status: LessonStatus.learning, errorMessage: f.message),
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
          savedProgress: null,
        ),
      ),
    );
  }

  /// Ulangi ujian dengan soal yang diundi ulang.
  Future<void> retryTest() => startTest();

  /// Kembali ke halaman belajar (dari ujian/hasil).
  void backToLearning() {
    _feedbackTicket++;
    emit(
      state.copyWith(
        status: LessonStatus.learning,
        phase: LessonPhase.idle,
        clearVoiceResult: true,
        clearChoicePick: true,
        choiceLocked: false,
        clearError: true,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── Soal suara ──

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

  // ─────────────────────────────────────────────────────────── Navigasi ──

  /// Lanjut ke soal berikutnya, atau selesaikan ujian di soal terakhir.
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
        clearError: true,
      ),
    );
  }

  Future<void> _finish() async {
    emit(state.copyWith(status: LessonStatus.finished, saving: true));
    final res = await repository.saveTestResult(
      surahId: state.lesson.surahId,
      score: state.score,
    );
    if (isClosed) return;
    res.fold(
      ifLeft: (f) => emit(
        state.copyWith(
          saving: false,
          errorMessage: 'Nilai gagal tersimpan: ${f.message}',
        ),
      ),
      ifRight: (progress) =>
          emit(state.copyWith(saving: false, savedProgress: progress)),
    );
  }

  @override
  Future<void> close() async {
    await _recorder.dispose();
    return super.close();
  }
}
