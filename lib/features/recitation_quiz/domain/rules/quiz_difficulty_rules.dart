import 'dart:math';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/weighted_quiz_rule.dart';

/// Distribusi soal dan multiplier untuk tiap tingkat kesulitan sesi.
class QuizDifficultyRules {
  QuizDifficultyRules._();

  /// Mudah: 80% soal Mudah, 20% Sedang, tanpa soal Sulit.
  static const easyMix = <WeightedQuizRule<QuizDifficulty>>[
    WeightedQuizRule(QuizDifficulty.easy, 80),
    WeightedQuizRule(QuizDifficulty.medium, 20),
  ];

  /// Sedang: 40% Mudah, 40% Sedang, 20% Sulit.
  static const mediumMix = <WeightedQuizRule<QuizDifficulty>>[
    WeightedQuizRule(QuizDifficulty.easy, 40),
    WeightedQuizRule(QuizDifficulty.medium, 40),
    WeightedQuizRule(QuizDifficulty.hard, 20),
  ];

  /// Sulit: 10% Mudah, 30% Sedang, 60% Sulit.
  static const hardMix = <WeightedQuizRule<QuizDifficulty>>[
    WeightedQuizRule(QuizDifficulty.easy, 10),
    WeightedQuizRule(QuizDifficulty.medium, 30),
    WeightedQuizRule(QuizDifficulty.hard, 60),
  ];

  static List<WeightedQuizRule<QuizDifficulty>> mixFor(
    QuizDifficulty difficulty,
  ) => switch (difficulty) {
    QuizDifficulty.easy => easyMix,
    QuizDifficulty.medium => mediumMix,
    QuizDifficulty.hard => hardMix,
  };

  static QuizDifficulty rollQuestionDifficulty(
    QuizDifficulty sessionDifficulty,
    Random rng,
  ) => WeightedQuizPicker.pick(mixFor(sessionDifficulty), rng);

  /// Multiplier skor akhir/leaderboard. Skor dasar tetap ditampilkan terpisah.
  static double scoreMultiplier(QuizDifficulty difficulty) =>
      switch (difficulty) {
        QuizDifficulty.easy => 1,
        QuizDifficulty.medium => 1.5,
        QuizDifficulty.hard => 2,
      };

  /// Mode Suara bernilai dua kali karena membutuhkan hafalan aktif dan
  /// pemeriksaan rekaman; Pilihan menjadi nilai dasar.
  static double modeScoreMultiplier(QuizMode mode) => mode.isVoice ? 2 : 1;

  /// Multiplier akhir diterapkan berurutan: mode lalu tingkat kesulitan.
  /// Pilihan 1/1.5/2, Suara 2/3/4.
  static double xpMultiplier(QuizMode mode, QuizDifficulty difficulty) {
    return modeScoreMultiplier(mode) * scoreMultiplier(difficulty);
  }
}
