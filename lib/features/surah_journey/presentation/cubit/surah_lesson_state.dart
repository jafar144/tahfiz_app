import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';

/// Tahapan layar sesi satu surah.
enum LessonStatus {
  /// Halaman belajar (kartu materi).
  learning,

  /// Menyiapkan soal ujian.
  loading,

  /// Sedang mengerjakan ujian.
  testing,

  /// Ujian selesai — layar hasil.
  finished,
}

/// Fase menjawab SOAL SUARA.
enum LessonPhase { idle, recording, processing, revealed }

class SurahLessonState {
  final SurahLesson lesson;
  final LessonStatus status;

  /// Seluruh ayat surah (halaman belajar "Baca Surahnya").
  final List<Ayah> surahAyat;

  // ── Ujian ──────────────────────────────────────────────────────────────
  final List<LessonQuestion> questions;
  final int currentIndex;
  final LessonPhase phase;

  /// Hasil pemeriksaan bacaan soal suara SAAT INI (fase revealed).
  final RecitationResult? voiceResult;

  /// Opsi terpilih soal pilihan saat ini (terkunci setelah memilih).
  final int? choicePick;
  final bool choiceLocked;

  /// Benar/salah per soal yang sudah dijawab (urut soal).
  final List<bool> answers;

  // ── Hasil & penyimpanan ────────────────────────────────────────────────
  final bool saving;

  /// Progres surah setelah hasil tersimpan (berisi best score & completed).
  final SurahProgress? savedProgress;

  final String? errorMessage;

  const SurahLessonState({
    required this.lesson,
    this.status = LessonStatus.learning,
    this.surahAyat = const [],
    this.questions = const [],
    this.currentIndex = 0,
    this.phase = LessonPhase.idle,
    this.voiceResult,
    this.choicePick,
    this.choiceLocked = false,
    this.answers = const [],
    this.saving = false,
    this.savedProgress,
    this.errorMessage,
  });

  LessonQuestion? get currentQuestion =>
      (currentIndex >= 0 && currentIndex < questions.length)
      ? questions[currentIndex]
      : null;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  int get correctCount => answers.where((a) => a).length;

  /// Nilai akhir 0..100 (per soal bernilai sama).
  int get score =>
      questions.isEmpty ? 0 : (correctCount * 100 / questions.length).round();

  bool get passed => score >= LessonConfig.passScore;

  SurahLessonState copyWith({
    LessonStatus? status,
    List<Ayah>? surahAyat,
    List<LessonQuestion>? questions,
    int? currentIndex,
    LessonPhase? phase,
    RecitationResult? voiceResult,
    bool clearVoiceResult = false,
    int? choicePick,
    bool clearChoicePick = false,
    bool? choiceLocked,
    List<bool>? answers,
    bool? saving,
    SurahProgress? savedProgress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SurahLessonState(
      lesson: lesson,
      status: status ?? this.status,
      surahAyat: surahAyat ?? this.surahAyat,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      voiceResult: clearVoiceResult ? null : (voiceResult ?? this.voiceResult),
      choicePick: clearChoicePick ? null : (choicePick ?? this.choicePick),
      choiceLocked: choiceLocked ?? this.choiceLocked,
      answers: answers ?? this.answers,
      saving: saving ?? this.saving,
      savedProgress: savedProgress ?? this.savedProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
