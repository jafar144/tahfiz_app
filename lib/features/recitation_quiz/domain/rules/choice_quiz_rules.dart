import 'dart:math';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_question_types.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/weighted_quiz_rule.dart';

/// Seluruh aturan gameplay mode PILIHAN.
///
/// Sesi adalah time-attack. Label soal inti mengikuti distribusi tingkat
/// kesulitan sesi; bonus hanya ditampilkan setelah streak sempurna.
class ChoiceQuizRules {
  ChoiceQuizRules._();

  // ── Sesi dan susunan soal ────────────────────────────────────────────────

  static const int sessionSeconds = 60;
  static const int poolCount = 40;
  static const int topUpThreshold = 10;
  static const int optionCount = 6;
  static const int maxAnswerAyah = 3;

  /// Sesuai keputusan gameplay: 1–2 ayat = Mudah, 3 ayat = Sedang.
  static QuizDifficulty continuationDifficulty(int ayahCount) =>
      ayahCount <= 2 ? QuizDifficulty.easy : QuizDifficulty.medium;

  /// Generator menyisipkan CADANGAN bonus secara berkala. Cadangan ini tidak
  /// tampil berdasarkan posisi; cubit memindahkannya tepat setelah streak 5.
  static const int bonusReserveEveryNQuestions = 5;

  static bool isBonusPosition(int oneBasedPosition) =>
      oneBasedPosition > 0 &&
      oneBasedPosition % bonusReserveEveryNQuestions == 0;

  /// Pada slot bonus dan ketika bank kosakata tersedia: 50% matching kosakata,
  /// 50% trivia surah. Bila matching tak dapat dibentuk, fallback ke trivia.
  static const List<WeightedQuizRule<ChoiceBonusSource>>
  bonusSourceDistribution = [
    WeightedQuizRule(ChoiceBonusSource.vocabularyMatch, 1),
    WeightedQuizRule(ChoiceBonusSource.surahTrivia, 1),
  ];

  static ChoiceBonusSource rollBonusSource(Random rng) =>
      WeightedQuizPicker.pick(bonusSourceDistribution, rng);

  /// Trivia surah berotasi merata: nama+arti, jumlah ayat, nomor urut. Urutan
  /// awal diacak, lalu setiap tipe mendapat 1/3 slot trivia yang berhasil dibuat.
  static const List<QuizBonusType> rotatingTriviaTypes = [
    QuizBonusType.nameMeaning,
    QuizBonusType.ayahCount,
    QuizBonusType.orderNumber,
  ];

  // ── Poin dan waktu ──────────────────────────────────────────────────────

  /// Lanjutan ayat benar: 1 ayat=10, 2=14, 3=18 poin. Salah=0.
  static int continuationPoints(int ayahCount) => 4 * ayahCount + 6;

  /// Lanjutan ayat benar: tambahan waktu sama dengan jumlah ayat (+1..+3).
  static int continuationTimeBonus(int ayahCount) => ayahCount;

  /// Arti kosakata tunggal memakai nilai soal lanjutan satu ayat: 10 poin dan
  /// +1 detik ketika benar.
  static int get vocabularyMeaningPoints => continuationPoints(1);
  static int get vocabularyMeaningTimeBonus => continuationTimeBonus(1);

  /// Semua bonus Pilihan bernilai penuh 20 poin dan +8 detik. Nama+arti yang
  /// hanya benar satu bagian mendapat setengah: 10 poin dan +4 detik.
  static const int bonusPoints = 20;
  static const int bonusTimeRewardSeconds = 8;
  static const int bonusQuestionSeconds = 15;

  static const Duration bonusIntroDuration = Duration(milliseconds: 1300);
  static const Duration bonusRewardDuration = Duration(milliseconds: 1600);
  static const Duration feedbackDuration = Duration(milliseconds: 700);
}
