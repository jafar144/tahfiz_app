import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar rekap akhir sesi kuis (mode suara & pilihan).
class QuizResultView extends StatelessWidget {
  final QuizResult result;
  final bool saving;
  final String? saveError;
  final QuizEnergy? energy;
  final VoidCallback onPlayAgain;
  final VoidCallback? onRefillReady;
  final VoidCallback onFinish;

  const QuizResultView({
    super.key,
    required this.result,
    required this.saving,
    required this.saveError,
    this.energy,
    required this.onPlayAgain,
    this.onRefillReady,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isChoice = result.mode.isChoice;
    // Mode pilihan tak memakai energi → selalu bisa main lagi.
    final canPlay = isChoice || (energy?.canPlay ?? true);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            const Spacer(),
            Text(
              isChoice ? _gradePoints(result.totalPoints) : _grade(result.averageScore),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isChoice ? 'Total poinmu' : 'Nilai akhirmu',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            if (isChoice)
              _PointsBadge(points: result.totalPoints)
            else
              ScoreRing(percent: result.averageScore, size: 180, caption: 'nilai'),

            const SizedBox(height: 16),
            Text(
              isChoice
                  ? '${result.passedCount} benar dari ${result.questionCount} soal'
                  : '${result.passedCount} dari ${result.questionCount} soal lolos',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            _ScoreDots(scores: result.scores, choice: isChoice),
            const SizedBox(height: 12),
            _saveStatus(context),
            const Spacer(),

            // Energi hanya relevan pada mode suara.
            if (!isChoice && energy != null && !energy!.isFull) ...[
              EnergyHint(energy: energy!, onRefillReady: onRefillReady),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canPlay ? onPlayAgain : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(canPlay
                    ? Icons.refresh_rounded
                    : Icons.hourglass_bottom_rounded),
                label: Text(
                    canPlay ? 'Main Lagi' : 'Energi habis',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
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

  static String _gradePoints(int points) {
    if (points >= 120) return 'Luar Biasa! 🌟';
    if (points >= 80) return 'Masyaa Allah!';
    if (points >= 40) return 'Bagus, terus berlatih!';
    return 'Ayo semangat berlatih!';
  }
}

/// Badge poin besar untuk mode pilihan.
class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuizColors.gold,
            QuizColors.goldDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: QuizColors.gold.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: points),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
          const Text(
            'poin',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deret titik skor per soal.
class _ScoreDots extends StatelessWidget {
  final List<int> scores;
  final bool choice;

  const _ScoreDots({required this.scores, this.choice = false});

  Color _color(int score) {
    // Mode pilihan: benar (poin>0) hijau, salah merah.
    if (choice) return score > 0 ? QuizColors.correct : QuizColors.missing;
    return QuizColors.forScore(score);
  }

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Text(
        'Tidak ada soal terjawab',
        style: TextStyle(fontSize: 12.5, color: Colors.black45),
      );
    }
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
              color: _color(scores[i]).withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _color(scores[i]).withValues(alpha: 0.5)),
            ),
            child: Text(
              '${scores[i]}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _color(scores[i]),
              ),
            ),
          ),
      ],
    );
  }
}
