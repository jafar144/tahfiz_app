import 'dart:math';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_question_types.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/weighted_quiz_rule.dart';

/// Seluruh aturan gameplay mode SUARA.
///
/// Generator dan penilaian wajib mengambil nilai dari sini. Distribusi label
/// Mudah/Sedang/Sulit lintas mode berada di `quiz_difficulty_rules.dart`.
class VoiceQuizRules {
  VoiceQuizRules._();

  // ── Komposisi sesi ───────────────────────────────────────────────────────

  static const int questionCount = 10;

  /// Urutan akhir soal Suara diacak setelah semua soal selesai dibentuk.
  static const bool shuffleQuestions = true;

  // ── Panjang jawaban dan waktu ────────────────────────────────────────────

  static const int shortAyahMaxWords = 6;
  static const int mediumAyahMaxWords = 13;
  static const (int, int) shortAnswerRange = (3, 4);
  static const (int, int) mediumAnswerRange = (2, 2);
  static const (int, int) longAnswerRange = (1, 1);
  static const int maxAnswerAyah = 4;
  static const int specificAyahMaxNumber = 5;

  /// Lanjutan dengan total maksimal 20 kata = Mudah; di atasnya = Sedang.
  static const int easyContinuationMaxTotalWords = 20;

  static QuizDifficulty continuationDifficulty(int totalWords) =>
      totalWords <= easyContinuationMaxTotalWords
      ? QuizDifficulty.easy
      : QuizDifficulty.medium;

  static const int fallbackQuestionSeconds = 30;
  static const int shortQuestionSeconds = 30;
  static const int mediumQuestionSeconds = 45;
  static const int longQuestionSeconds = 60;

  /// Tebak ayat dari makna selalu 60 detik. Petunjuk Arab muncul ketika waktu
  /// tersisa 30 detik.
  static const int meaningToAyahSeconds = 60;
  static const int meaningToAyahHintAtSeconds = 30;
  static const QuizDifficulty meaningToAyahDifficulty = QuizDifficulty.hard;
  static const int meaningToAyahFastBonusPoints = 10;

  static bool earnsMeaningToAyahFastBonus({
    required bool passed,
    required int secondsLeft,
  }) => passed && secondsLeft > meaningToAyahHintAtSeconds;

  static (int, int) answerRangeForWordCount(int words) =>
      words <= shortAyahMaxWords
      ? shortAnswerRange
      : words <= mediumAyahMaxWords
      ? mediumAnswerRange
      : longAnswerRange;

  static int questionSecondsForWordCount(int words) =>
      words <= shortAyahMaxWords
      ? shortQuestionSeconds
      : words <= mediumAyahMaxWords
      ? mediumQuestionSeconds
      : longQuestionSeconds;

  // ── Penilaian bacaan ────────────────────────────────────────────────────

  static const int maxAttempts = 2;
  static const int passThreshold = 80;
  static const int perfectThreshold = 90;
  static const int retryPrepSeconds = 5;

  static bool passes(int accuracyPercent) => accuracyPercent >= passThreshold;

  /// Lolos di atas 90% dibulatkan menjadi 100. Gagal setelah dua percobaan
  /// tetap memperoleh persentase terbaiknya sebagai skor soal.
  static int finalScore({
    required int accuracyPercent,
    required int bestAccuracyPercent,
  }) => passes(accuracyPercent)
      ? (accuracyPercent > perfectThreshold ? 100 : accuracyPercent)
      : bestAccuracyPercent;

  // ── Bonus Suara ─────────────────────────────────────────────────────────

  /// Jika bank kosakata tersedia: 50% mencocokkan kosakata dan 50% pengetahuan
  /// surah. Jika tidak tersedia, selalu fallback ke pengetahuan surah.
  static const List<WeightedQuizRule<VoiceBonusSource>>
  bonusSourceDistribution = [
    WeightedQuizRule(VoiceBonusSource.vocabularyMatch, 1),
    WeightedQuizRule(VoiceBonusSource.surahKnowledge, 1),
  ];

  static VoiceBonusSource rollBonusSource(Random rng) =>
      WeightedQuizPicker.pick(bonusSourceDistribution, rng);

  /// Di dalam pengetahuan surah, semua tipe yang VALID diundi rata. Jika kelima
  /// tipe valid, masing-masing 20% dari jalur pengetahuan surah (atau 10% dari
  /// seluruh bonus ketika jalur kosakata juga tersedia).
  static const List<WeightedQuizRule<QuizBonusType>> knowledgeTypeDistribution =
      [
        WeightedQuizRule(QuizBonusType.identify, 1),
        WeightedQuizRule(QuizBonusType.neighbor, 1),
        WeightedQuizRule(QuizBonusType.nameMeaning, 1),
        WeightedQuizRule(QuizBonusType.orderNumber, 1),
        WeightedQuizRule(QuizBonusType.ayahCount, 1),
      ];

  static const int bonusPrepSeconds = 5;
  static const int bonusPrepSplashSeconds = 2;
  static const int bonusPoints = 35;
  static const int bonusSecondsEasy = 15;
  static const int bonusSecondsMedium = 20;
  static const int bonusSecondsHard = 30;

  static QuizDifficulty bonusDifficulty(QuizBonusType type) => switch (type) {
    QuizBonusType.identify => QuizDifficulty.easy,
    QuizBonusType.ayahCount ||
    QuizBonusType.nameMeaning => QuizDifficulty.medium,
    QuizBonusType.neighbor || QuizBonusType.orderNumber => QuizDifficulty.hard,
  };

  static int bonusSeconds(QuizDifficulty difficulty) => switch (difficulty) {
    QuizDifficulty.easy => bonusSecondsEasy,
    QuizDifficulty.medium => bonusSecondsMedium,
    QuizDifficulty.hard => bonusSecondsHard,
  };
}
