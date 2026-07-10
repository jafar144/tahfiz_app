import 'dart:math';

import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Palet & widget bersama bergaya "malam islami" Petualangan Surah — dipakai
/// peta journey, halaman surah, layar belajar/test/hasil agar senada.
class JourneyColors {
  JourneyColors._();

  static const skyTop = Color(0xFF0B2540);
  static const skyBottom = Color(0xFF123B33);

  /// Permukaan kartu di atas langit malam.
  static const card = Color(0xFF14324A);
  static const cardBorder = Color(0x22FFFFFF);
}

/// Latar gradien malam + taburan bintang halus (tanpa bukit — dipakai halaman
/// konten; bukit khusus peta).
class JourneyBackground extends StatelessWidget {
  final Widget child;

  const JourneyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [JourneyColors.skyTop, JourneyColors.skyBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _StarsPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(11); // seed tetap → pola stabil
    final paint = Paint();
    final count = (size.height / 26).round();
    for (var i = 0; i < count; i++) {
      paint.color = Colors.white.withValues(
        alpha: 0.10 + rng.nextDouble() * 0.30,
      );
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.6 + rng.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

/// Dekorasi kartu gelap standar journey.
BoxDecoration journeyCardDecoration({Color? borderColor, double radius = 18}) {
  return BoxDecoration(
    color: JourneyColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? JourneyColors.cardBorder),
  );
}

/// Pil total XP (bintang emas) — top bar peta & layar hasil.
class XpBadge extends StatelessWidget {
  final int xp;

  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: QuizColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: QuizColors.gold),
          const SizedBox(width: 5),
          Text(
            '$xp XP',
            style: const TextStyle(
              color: QuizColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip kecil biaya energi test (mis. "⚡1").
class EnergyCostChip extends StatelessWidget {
  final int cost;

  const EnergyCostChip({super.key, this.cost = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB020).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.55),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFFB020)),
          Text(
            '$cost',
            style: const TextStyle(
              color: Color(0xFFFFB020),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Teks Arab (font mushaf) dengan bagian [highlight] disorot emas; dipakai
/// kartu kosa kata & soal arti kata. Bila [highlight] tidak ditemukan pada
/// [text], seluruh ayat tampil tanpa sorotan (fallback aman).
class HighlightedAyahText extends StatelessWidget {
  final String text;
  final String? highlight;
  final double fontSize;

  const HighlightedAyahText({
    super.key,
    required this.text,
    this.highlight,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'QuranHafs',
      fontSize: fontSize,
      height: 1.95,
      color: Colors.white,
    );
    final word = highlight;
    final idx = (word == null || word.isEmpty) ? -1 : text.indexOf(word);

    return Text.rich(
      idx < 0
          ? TextSpan(text: text, style: base)
          : TextSpan(
              style: base,
              children: [
                TextSpan(text: text.substring(0, idx)),
                TextSpan(
                  text: word,
                  style: TextStyle(
                    color: QuizColors.gold,
                    fontWeight: FontWeight.bold,
                    backgroundColor: QuizColors.gold.withValues(alpha: 0.14),
                  ),
                ),
                TextSpan(text: text.substring(idx + word!.length)),
              ],
            ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}

/// Tombol aksi utama emas (gaya journey) selebar layar — QuizButton ala
/// Duolingo (bibir 3D + getar saat ditekan).
class JourneyPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;

  /// Tampilkan chip biaya energi di samping label.
  final bool showEnergyCost;

  const JourneyPrimaryButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.showEnergyCost = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: QuizButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        color: QuizColors.goldDark,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        trailing: showEnergyCost ? const EnergyCostChip() : null,
      ),
    );
  }
}

/// Tombol sekunder (permukaan gelap) selebar layar — gaya journey, juga
/// memakai QuizButton agar efek tekan & getarnya seragam.
class JourneySecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;

  const JourneySecondaryButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: QuizButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        color: QuizColors.nightButton,
        foregroundColor: Colors.white,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      ),
    );
  }
}
