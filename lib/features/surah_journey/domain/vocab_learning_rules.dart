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
  static const int phaseThreeMeaningRecallCount = 5;

  static const int totalQuestionCount =
      phaseOneArabicToMeaningCount +
      phaseTwoArabicToMeaningCount +
      phaseTwoMeaningToArabicCount +
      phaseTwoMatchCount +
      phaseThreeMeaningRecallCount;

  /// Ambang lulus 80% dari 20 aktivitas.
  static const int minCorrect = 16;

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
}
