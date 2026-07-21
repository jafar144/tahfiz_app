import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Label tingkat kesulitan yang dipakai bersama oleh layar kuis suara dan
/// pilihan. Palet menyesuaikan latar terang atau gelap agar tetap terbaca.
class QuizDifficultyBadge extends StatelessWidget {
  final QuizDifficulty difficulty;
  final bool light;

  const QuizDifficultyBadge({
    super.key,
    required this.difficulty,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch ((difficulty, light)) {
      (QuizDifficulty.easy, true) => const Color(0xFF35A96F),
      (QuizDifficulty.easy, false) => const Color(0xFF6EE7A8),
      (QuizDifficulty.medium, true) => const Color(0xFF9A6900),
      (QuizDifficulty.medium, false) => QuizColors.gold,
      (QuizDifficulty.hard, true) => const Color(0xFFE05252),
      (QuizDifficulty.hard, false) => const Color(0xFFFF7B7B),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
