import 'package:equatable/equatable.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';

/// Status keseluruhan sesi kuis.
enum QuizStatus { intro, loading, error, playing, finished }

/// Fase pengerjaan satu soal.
enum AnswerPhase {
  /// Menunggu santri mulai merekam.
  idle,

  /// Sedang merekam.
  recording,

  /// Audio sedang diperiksa.
  processing,

  /// Hasil percobaan sudah keluar (lolos / boleh ulang / kunci dibuka).
  revealed,
}

class RecitationQuizState extends Equatable {
  final QuizStatus status;
  final String? errorMessage;

  final List<QuizQuestion> questions;
  final int currentIndex;

  final AnswerPhase phase;

  /// Percobaan ke- (1 atau 2) untuk soal saat ini.
  final int attempt;

  /// Hasil percobaan terakhir (untuk menampilkan persentase segera).
  final RecitationResult? currentResult;

  /// Persentase terbaik lintas percobaan pada soal saat ini.
  final int bestPercent;

  /// Hasil percobaan terbaik (untuk koreksi saat kunci dibuka).
  final RecitationResult? bestResult;

  /// True bila soal saat ini lolos (≥80%).
  final bool passed;

  /// True bila kunci jawaban dibuka (gagal 2x) — tampilkan jawaban + koreksi.
  final bool revealAnswer;

  /// Jawaban soal saat ini yang sudah difinalisasi (skor diketahui); null bila
  /// belum final (mis. masih boleh diulang).
  final QuizAnswer? pendingAnswer;

  final List<QuizAnswer> answers;
  final QuizResult? result;

  final bool saving;
  final String? saveError;

  const RecitationQuizState({
    this.status = QuizStatus.intro,
    this.errorMessage,
    this.questions = const [],
    this.currentIndex = 0,
    this.phase = AnswerPhase.idle,
    this.attempt = 1,
    this.currentResult,
    this.bestPercent = 0,
    this.bestResult,
    this.passed = false,
    this.revealAnswer = false,
    this.pendingAnswer,
    this.answers = const [],
    this.result,
    this.saving = false,
    this.saveError,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get total => questions.length;
  int get questionNumber => currentIndex + 1;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  /// Boleh mengulang: gagal di percobaan 1 dan kunci belum dibuka.
  bool get canRetry =>
      phase == AnswerPhase.revealed &&
      !passed &&
      attempt == 1 &&
      !revealAnswer;

  /// Boleh lanjut: soal sudah difinalisasi.
  bool get canAdvance =>
      phase == AnswerPhase.revealed && pendingAnswer != null;

  bool get isProcessing => phase == AnswerPhase.processing;
  bool get isRecording => phase == AnswerPhase.recording;

  RecitationQuizState copyWith({
    QuizStatus? status,
    String? errorMessage,
    List<QuizQuestion>? questions,
    int? currentIndex,
    AnswerPhase? phase,
    int? attempt,
    RecitationResult? currentResult,
    int? bestPercent,
    RecitationResult? bestResult,
    bool? passed,
    bool? revealAnswer,
    QuizAnswer? pendingAnswer,
    List<QuizAnswer>? answers,
    QuizResult? result,
    bool? saving,
    String? saveError,
    bool clearError = false,
    bool clearCurrentResult = false,
    bool clearBestResult = false,
    bool clearPendingAnswer = false,
    bool clearSaveError = false,
  }) {
    return RecitationQuizState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      attempt: attempt ?? this.attempt,
      currentResult:
          clearCurrentResult ? null : (currentResult ?? this.currentResult),
      bestPercent: bestPercent ?? this.bestPercent,
      bestResult: clearBestResult ? null : (bestResult ?? this.bestResult),
      passed: passed ?? this.passed,
      revealAnswer: revealAnswer ?? this.revealAnswer,
      pendingAnswer:
          clearPendingAnswer ? null : (pendingAnswer ?? this.pendingAnswer),
      answers: answers ?? this.answers,
      result: result ?? this.result,
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        questions,
        currentIndex,
        phase,
        attempt,
        currentResult,
        bestPercent,
        bestResult,
        passed,
        revealAnswer,
        pendingAnswer,
        answers,
        result,
        saving,
        saveError,
      ];
}
