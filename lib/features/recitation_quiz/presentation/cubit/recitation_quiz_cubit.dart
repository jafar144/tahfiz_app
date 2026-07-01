import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';

class RecitationQuizCubit extends Cubit<RecitationQuizState> {
  final QuizRepository repository;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;

  /// Jumlah soal per sesi.
  static const int kQuestionCount = 10;

  /// Ambang lolos & nilai penuh.
  static const int kPassThreshold = 80;
  static const int kPerfectThreshold = 90;

  RecitationQuizCubit(this.repository) : super(const RecitationQuizState());

  /// Mulai / mulai ulang sesi: susun 10 soal baru.
  Future<void> start() async {
    emit(const RecitationQuizState(status: QuizStatus.loading));
    final res = await repository.generateQuestions(count: kQuestionCount);
    res.fold(
      ifLeft: (f) => emit(state.copyWith(
        status: QuizStatus.error,
        errorMessage: f.message,
      )),
      ifRight: (qs) => emit(RecitationQuizState(
        status: QuizStatus.playing,
        questions: qs,
        phase: AnswerPhase.idle,
      )),
    );
  }

  Future<void> startRecording() async {
    if (state.currentQuestion == null) return;
    try {
      if (!await _recorder.hasPermission()) {
        emit(state.copyWith(
          errorMessage: 'Izin mikrofon ditolak. Aktifkan di pengaturan.',
        ));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/quiz_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recordPath = path;
      emit(state.copyWith(phase: AnswerPhase.recording, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal memulai rekaman: $e'));
    }
  }

  /// Hentikan rekaman lalu periksa terhadap ayat jawaban.
  Future<void> stopAndCheck() async {
    final q = state.currentQuestion;
    if (q == null) return;
    try {
      final stopped = await _recorder.stop();
      final path = stopped ?? _recordPath;
      if (path == null) {
        emit(state.copyWith(
          phase: AnswerPhase.idle,
          errorMessage: 'Rekaman tidak tersimpan.',
        ));
        return;
      }
      emit(state.copyWith(phase: AnswerPhase.processing, clearError: true));

      final res = await repository.checkAnswer(
        answerAyat: q.answer,
        audioFilePath: path,
        mimeType: 'audio/mp4',
      );
      res.fold(
        ifLeft: (f) => emit(state.copyWith(
          phase: AnswerPhase.idle,
          errorMessage: f.message,
        )),
        ifRight: _applyResult,
      );
    } catch (e) {
      emit(state.copyWith(
        phase: AnswerPhase.idle,
        errorMessage: 'Gagal memproses bacaan: $e',
      ));
    }
  }

  void _applyResult(RecitationResult result) {
    final pct = result.accuracyPercent;
    final best = pct > state.bestPercent ? pct : state.bestPercent;
    final bestResult = pct >= state.bestPercent ? result : state.bestResult;

    // Gagal (<80%) di percobaan 1 → beri kesempatan ulang, belum difinalisasi.
    if (pct < kPassThreshold && state.attempt == 1) {
      emit(state.copyWith(
        phase: AnswerPhase.revealed,
        currentResult: result,
        bestPercent: best,
        bestResult: bestResult,
        passed: false,
        revealAnswer: false,
      ));
      return;
    }

    // Finalisasi: lolos, atau gagal 2x.
    final bool passed = pct >= kPassThreshold;
    final bool reveal = !passed; // gagal 2x → buka kunci
    final int score = passed
        ? (pct > kPerfectThreshold ? 100 : pct)
        : best; // gagal 2x → persentase terbaik dari 2 percobaan

    final pending = QuizAnswer(
      questionIndex: state.currentIndex,
      score: score,
      attempts: state.attempt,
      passed: passed,
      bestResult: passed ? result : bestResult,
    );

    emit(state.copyWith(
      phase: AnswerPhase.revealed,
      currentResult: result,
      bestPercent: best,
      bestResult: bestResult,
      passed: passed,
      revealAnswer: reveal,
      pendingAnswer: pending,
    ));
  }

  /// Ulangi soal (percobaan ke-2).
  void retry() {
    emit(state.copyWith(
      phase: AnswerPhase.idle,
      attempt: 2,
      passed: false,
      revealAnswer: false,
      clearCurrentResult: true,
    ));
  }

  /// Lanjut ke soal berikutnya, atau selesaikan sesi bila soal terakhir.
  Future<void> next() async {
    final pending = state.pendingAnswer;
    if (pending == null) return;
    final answers = [...state.answers, pending];

    if (state.isLastQuestion) {
      final result = QuizResult(
        answers: answers,
        questionCount: state.questions.length,
      );
      emit(state.copyWith(
        status: QuizStatus.finished,
        answers: answers,
        result: result,
        saving: true,
        clearSaveError: true,
      ));
      final save = await repository.saveAttempt(
        totalScore: result.totalScore,
        questionScores: result.scores,
      );
      save.fold(
        ifLeft: (f) => emit(state.copyWith(saving: false, saveError: f.message)),
        ifRight: (_) => emit(state.copyWith(saving: false)),
      );
      return;
    }

    emit(state.copyWith(
      answers: answers,
      currentIndex: state.currentIndex + 1,
      phase: AnswerPhase.idle,
      attempt: 1,
      bestPercent: 0,
      passed: false,
      revealAnswer: false,
      clearCurrentResult: true,
      clearBestResult: true,
      clearPendingAnswer: true,
    ));
  }

  /// Main lagi dari awal (soal baru).
  Future<void> playAgain() => start();

  @override
  Future<void> close() async {
    await _recorder.dispose();
    return super.close();
  }
}
