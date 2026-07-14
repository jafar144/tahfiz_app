import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';

/// Seluruh angka dan komposisi pembelajaran Kosa Kata Journey.
class VocabLearningRules {
  VocabLearningRules._();

  // Fase 1: Arab → arti.
  static const int phaseOneArabicToMeaningCount = 5;

  // Fase 2: campuran dua arah dan papan pasangan.
  static const int phaseTwoArabicToMeaningCount = 4;
  static const int phaseTwoMeaningToArabicCount = 4;
  static const int phaseTwoMatchCount = 2;

  // Fase 3: arti → ucapkan potongan Arab, tanpa timer.
  static const int phaseThreeMeaningRecallCount = 3;

  static const int totalQuestionCount =
      phaseOneArabicToMeaningCount +
      phaseTwoArabicToMeaningCount +
      phaseTwoMeaningToArabicCount +
      phaseTwoMatchCount +
      phaseThreeMeaningRecallCount;

  /// Ambang lulus lama untuk paket gabungan. Dipertahankan agar progres versi
  /// sebelumnya tetap dapat dibaca, tetapi sesi baru dinilai per fase.
  static const int minCorrect = 15;

  /// Dua dari sepuluh soal Ujian Akhir memakai recall makna → Arab.
  static const int examMeaningRecallCount = 2;

  static int questionCountFor(VocabLearningPhase phase) => switch (phase) {
    VocabLearningPhase.arabicToMeaning => phaseOneArabicToMeaningCount,
    VocabLearningPhase.mixedPractice =>
      phaseTwoArabicToMeaningCount +
          phaseTwoMeaningToArabicCount +
          phaseTwoMatchCount,
    VocabLearningPhase.meaningRecall => phaseThreeMeaningRecallCount,
  };

  /// Setiap kuis berdiri sendiri dengan ambang minimal 80%.
  static int minCorrectFor(VocabLearningPhase phase) => switch (phase) {
    VocabLearningPhase.arabicToMeaning => 4,
    VocabLearningPhase.mixedPractice => 8,
    VocabLearningPhase.meaningRecall => 3,
  };

  /// Kuis 1 dan 2 memakai kunci progres tambahan. Kuis 3 tetap memakai kunci
  /// bagian utama agar kelulusannya membuka Ujian Akhir seperti data lama.
  static String progressKey(String sectionId, VocabLearningPhase phase) =>
      phase == VocabLearningPhase.meaningRecall
      ? sectionId
      : '${sectionId}_quiz_${phase.number}';
}
