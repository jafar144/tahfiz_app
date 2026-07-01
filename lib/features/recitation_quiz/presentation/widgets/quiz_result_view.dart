import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar rekap akhir sesi kuis.
class QuizResultView extends StatelessWidget {
  final QuizResult result;
  final bool saving;
  final String? saveError;
  final VoidCallback onPlayAgain;
  final VoidCallback onFinish;

  const QuizResultView({
    super.key,
    required this.result,
    required this.saving,
    required this.saveError,
    required this.onPlayAgain,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final total = result.totalScore;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            const Spacer(),
            Text(
              _grade(total),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Nilai akhirmu',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ScoreRing(percent: total, size: 180, caption: 'nilai'),
            const SizedBox(height: 16),
            Text(
              '${result.passedCount} dari ${result.questionCount} soal lolos',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            _ScoreDots(scores: result.scores),
            const SizedBox(height: 12),
            _saveStatus(context),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlayAgain,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Main Lagi',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onFinish,
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveStatus(BuildContext context) {
    if (saving) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Menyimpan hasil…', style: TextStyle(color: Colors.black45)),
        ],
      );
    }
    if (saveError != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 16, color: QuizColors.missing),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Gagal menyimpan hasil',
                style: TextStyle(color: QuizColors.missing, fontSize: 12)),
          ),
        ],
      );
    }
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, size: 16, color: QuizColors.correct),
        SizedBox(width: 6),
        Text('Hasil tersimpan', style: TextStyle(color: Colors.black45)),
      ],
    );
  }

  static String _grade(int total) {
    if (total > 90) return 'Luar Biasa! 🌟';
    if (total >= 80) return 'Masyaa Allah!';
    if (total >= 60) return 'Bagus, terus berlatih!';
    return 'Ayo semangat berlatih!';
  }
}

/// Deret titik skor per soal.
class _ScoreDots extends StatelessWidget {
  final List<int> scores;
  const _ScoreDots({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < scores.length; i++)
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QuizColors.forScore(scores[i]).withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                  color: QuizColors.forScore(scores[i]).withValues(alpha: 0.5)),
            ),
            child: Text(
              '${scores[i]}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: QuizColors.forScore(scores[i]),
              ),
            ),
          ),
      ],
    );
  }
}
