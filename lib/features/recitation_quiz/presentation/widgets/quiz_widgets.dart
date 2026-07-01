import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';

/// Palet warna khusus kuis (gamifikasi, tetap selaras tema app).
class QuizColors {
  QuizColors._();

  static const gold = Color(0xFFF6A609);
  static const goldDark = Color(0xFFB9770B);
  static const correct = Color(0xFF2E7D32);
  static const wrong = Color(0xFFE65100);
  static const missing = Color(0xFFC62828);
  static const extra = Colors.blueGrey;

  /// Warna berdasarkan persentase skor.
  static Color forScore(int pct) {
    if (pct > 90) return correct;
    if (pct >= 80) return gold;
    return missing;
  }
}

/// Cincin skor beranimasi dengan angka persentase di tengah.
class ScoreRing extends StatelessWidget {
  final int percent;
  final double size;
  final Color? color;
  final String? caption;

  const ScoreRing({
    super.key,
    required this.percent,
    this.size = 140,
    this.color,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? QuizColors.forScore(percent);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: size * 0.09,
                  strokeCap: StrokeCap.round,
                  backgroundColor: ringColor.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation(ringColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.bold,
                      color: ringColor,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    caption ?? '%',
                    style: TextStyle(
                      fontSize: size * 0.12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bar progres bersegmen: satu segmen per soal.
class SegmentedProgress extends StatelessWidget {
  final int total;
  final int currentIndex; // 0-based
  final List<int> doneScores; // skor soal-soal yang sudah selesai

  const SegmentedProgress({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.doneScores,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < doneScores.length
                    ? QuizColors.forScore(doneScores[i])
                    : (i == currentIndex
                        ? primary
                        : primary.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Kartu menampilkan teks ayat prompt (buta — tanpa nama surah / nomor).
class PromptAyahCard extends StatelessWidget {
  final String text;

  const PromptAyahCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.06),
            scheme.primary.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'QuranHafs',
          fontSize: 30,
          height: 1.9,
          color: Color(0xFF212121),
        ),
      ),
    );
  }
}

/// Teks Arab jawaban dengan pewarnaan koreksi per kata (dari [WordDiff]).
class CorrectionText extends StatelessWidget {
  final List<WordDiff> diffs;
  final double fontSize;

  const CorrectionText({super.key, required this.diffs, this.fontSize = 26});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final d in diffs) {
      switch (d.status) {
        case WordStatus.correct:
          spans.add(TextSpan(
            text: '${d.referenceWordDisplay ?? d.referenceWord ?? ''} ',
            style: const TextStyle(color: QuizColors.correct),
          ));
        case WordStatus.wrong:
          spans.add(TextSpan(
            text: '${d.referenceWordDisplay ?? d.referenceWord ?? ''} ',
            style: const TextStyle(
              color: QuizColors.wrong,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dashed,
              decorationColor: QuizColors.wrong,
            ),
          ));
        case WordStatus.missing:
          spans.add(TextSpan(
            text: '${d.referenceWordDisplay ?? d.referenceWord ?? ''} ',
            style: const TextStyle(
              color: QuizColors.missing,
              decoration: TextDecoration.lineThrough,
              decorationColor: QuizColors.missing,
            ),
          ));
        case WordStatus.extra:
          final w = d.spokenWord ?? '';
          if (w.isEmpty) continue;
          spans.add(TextSpan(
            text: '$w ',
            style: const TextStyle(
              color: QuizColors.extra,
              decoration: TextDecoration.underline,
              decorationColor: QuizColors.extra,
            ),
          ));
      }
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'QuranHafs',
          fontSize: fontSize,
          height: 1.9,
        ),
      ),
    );
  }
}

/// Legenda singkat warna koreksi.
class CorrectionLegend extends StatelessWidget {
  const CorrectionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _LegendDot(color: QuizColors.correct, label: 'Benar'),
        _LegendDot(color: QuizColors.wrong, label: 'Salah'),
        _LegendDot(color: QuizColors.missing, label: 'Kelewat'),
        _LegendDot(color: QuizColors.extra, label: 'Tambahan'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
