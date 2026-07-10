import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';

/// Tahapan layar sesi satu surah.
enum LessonStatus {
  /// Daftar bagian surah (peta kecil di dalam surah).
  overview,

  /// Halaman belajar sebuah bagian (kartu materi).
  learning,

  /// Menyiapkan soal test.
  loading,

  /// Sedang mengerjakan test.
  testing,

  /// Test selesai — layar hasil.
  finished,
}

/// Fase menjawab SOAL SUARA.
enum LessonPhase { idle, recording, processing, revealed }

class SurahLessonState {
  final SurahLesson lesson;
  final LessonStatus status;

  /// False selama data awal (ayat + progres) masih dimuat — halaman
  /// menampilkan loading dedicated dulu sebelum daftar bagian muncul.
  final bool initialized;

  /// Progres surah ini milik pengguna (termuat saat init, diperbarui usai
  /// menyimpan hasil test).
  final SurahProgress progress;

  /// Bagian yang sedang dibuka/diuji; null = UJIAN AKHIR surah.
  final LessonSection? activeSection;

  /// Seluruh ayat surah (blok "Baca Surahnya" & penyusunan soal kosa kata).
  final List<Ayah> surahAyat;

  // ── Test ───────────────────────────────────────────────────────────────
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

  /// XP yang didapat dari test barusan (layar hasil); null = belum dihitung.
  final int? xpGained;

  final String? errorMessage;

  const SurahLessonState({
    required this.lesson,
    this.status = LessonStatus.overview,
    this.initialized = false,
    this.progress = SurahProgress.empty,
    this.activeSection,
    this.surahAyat = const [],
    this.questions = const [],
    this.currentIndex = 0,
    this.phase = LessonPhase.idle,
    this.voiceResult,
    this.choicePick,
    this.choiceLocked = false,
    this.answers = const [],
    this.saving = false,
    this.xpGained,
    this.errorMessage,
  });

  /// Test yang sedang berlangsung adalah UJIAN AKHIR surah.
  bool get isExam => status != LessonStatus.overview && activeSection == null;

  LessonQuestion? get currentQuestion =>
      (currentIndex >= 0 && currentIndex < questions.length)
      ? questions[currentIndex]
      : null;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  int get correctCount => answers.where((a) => a).length;

  /// Jumlah benar minimal test aktif agar lulus.
  int get minCorrect =>
      activeSection?.test.minCorrect ?? LessonConfig.examMinCorrect;

  bool get passed => correctCount >= minCorrect;

  /// Nilai 0..100 (untuk ujian akhir & tampilan).
  int get score =>
      questions.isEmpty ? 0 : (correctCount * 100 / questions.length).round();

  /// Seluruh bagian surah sudah lulus → ujian akhir terbuka.
  bool get examUnlocked =>
      progress.allSectionsPassed(lesson.sections.map((s) => s.id));

  /// Bagian [section] terbuka bila semua bagian sebelumnya sudah lulus.
  bool sectionUnlocked(LessonSection section) {
    for (final s in lesson.sections) {
      if (s.id == section.id) return true;
      if (!progress.of(s.id).passed) return false;
    }
    return true;
  }

  /// Bagian pertama yang belum lulus setelah [sectionId]; null = tidak ada.
  LessonSection? nextSectionAfter(String sectionId) {
    final sections = lesson.sections;
    final idx = sections.indexWhere((s) => s.id == sectionId);
    for (var i = idx + 1; i < sections.length; i++) {
      if (!progress.of(sections[i].id).passed) return sections[i];
    }
    return null;
  }

  SurahLessonState copyWith({
    LessonStatus? status,
    bool? initialized,
    SurahProgress? progress,
    LessonSection? activeSection,
    bool clearActiveSection = false,
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
    int? xpGained,
    bool clearXpGained = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SurahLessonState(
      lesson: lesson,
      status: status ?? this.status,
      initialized: initialized ?? this.initialized,
      progress: progress ?? this.progress,
      activeSection: clearActiveSection
          ? null
          : (activeSection ?? this.activeSection),
      surahAyat: surahAyat ?? this.surahAyat,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      voiceResult: clearVoiceResult ? null : (voiceResult ?? this.voiceResult),
      choicePick: clearChoicePick ? null : (choicePick ?? this.choicePick),
      choiceLocked: choiceLocked ?? this.choiceLocked,
      answers: answers ?? this.answers,
      saving: saving ?? this.saving,
      xpGained: clearXpGained ? null : (xpGained ?? this.xpGained),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
