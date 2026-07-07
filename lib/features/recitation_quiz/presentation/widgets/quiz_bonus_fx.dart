import 'dart:math';

import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Efek visual "Soal Bonus" yang dipakai bersama mode Pilihan & Suara:
/// gelombang emas di tepi, splash transisi, dan overlay hadiah beranimasi.

/// Gelombang emas tipis yang bergerak halus di sepanjang tepi layar bonus.
class GoldEdgeGlow extends StatefulWidget {
  const GoldEdgeGlow({super.key});

  @override
  State<GoldEdgeGlow> createState() => _GoldEdgeGlowState();
}

class _GoldEdgeGlowState extends State<GoldEdgeGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _GoldEdgeGlowPainter(_c.value),
      ),
    );
  }
}

class _GoldEdgeGlowPainter extends CustomPainter {
  /// Fase animasi 0..1.
  final double t;

  _GoldEdgeGlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Vignette emas lembut di tepi (pusat transparan).
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [
          Colors.transparent,
          QuizColors.gold.withValues(alpha: 0.0),
          QuizColors.gold.withValues(alpha: 0.14),
        ],
        stops: const [0.55, 0.82, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // Gelombang berjalan: sweep gradient berputar sepanjang bingkai.
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(3),
      const Radius.circular(30),
    );
    final glowOpacity = 0.4 + 0.2 * (0.5 + 0.5 * sin(2 * pi * t));
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = SweepGradient(
        transform: GradientRotation(2 * pi * t),
        colors: [
          QuizColors.gold.withValues(alpha: 0.0),
          QuizColors.gold.withValues(alpha: glowOpacity),
          QuizColors.goldDark.withValues(alpha: 0.12),
          QuizColors.gold.withValues(alpha: glowOpacity),
          QuizColors.gold.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, sweep);
  }

  @override
  bool shouldRepaint(_GoldEdgeGlowPainter old) => old.t != t;
}

/// Splash "SOAL BONUS" sesaat sebelum soal bonus muncul (transisi masuk).
class BonusIntroSplash extends StatelessWidget {
  final String subtitle;

  const BonusIntroSplash({
    super.key,
    this.subtitle = 'Soal spesial • poin lebih besar',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [QuizColors.gold, QuizColors.goldDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: QuizColors.gold.withValues(alpha: 0.5),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'SOAL BONUS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: QuizColors.goldDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay hadiah: sekilas "Benar!" lalu pill hadiah terbang ke arah HUD sambil
/// memudar. Bila [showTime] true → dua pill (poin + detik) ke dua sudut atas;
/// bila false → hanya pill poin, melesat ke atas (mode suara: tak ada bonus
/// waktu).
class BonusRewardOverlay extends StatefulWidget {
  final int points;
  final int seconds;
  final bool full;
  final bool showTime;

  const BonusRewardOverlay({
    super.key,
    required this.points,
    this.seconds = 0,
    required this.full,
    this.showTime = true,
  });

  @override
  State<BonusRewardOverlay> createState() => _BonusRewardOverlayState();
}

class _BonusRewardOverlayState extends State<BonusRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final introT = Curves.easeOutBack.transform((t / 0.30).clamp(0.0, 1.0));
        const flyStart = 0.52;
        final flyT = ((t - flyStart) / (1 - flyStart)).clamp(0.0, 1.0);
        final flyE = Curves.easeInCubic.transform(flyT);

        final cardOpacity = (introT * (1 - (flyT / 0.3).clamp(0.0, 1.0))).clamp(
          0.0,
          1.0,
        );
        final cardScale = (0.75 + 0.25 * introT) * (1 - 0.08 * flyE);

        final flyOut = ((flyE - 0.62) / 0.38).clamp(0.0, 1.0);
        final pillOpacity = (introT * (1 - flyOut)).clamp(0.0, 1.0);
        final pillScale = (0.75 + 0.25 * introT) * (1 - 0.45 * flyE);

        final scrimAlpha = 0.38 * introT * (1 - flyT);

        Widget flyingPill(Alignment start, Alignment target, Widget child) {
          return Align(
            alignment: Alignment.lerp(start, target, flyE)!,
            child: Opacity(
              opacity: pillOpacity,
              child: Transform.scale(scale: pillScale, child: child),
            ),
          );
        }

        final pointsPill = _RewardPill(
          icon: Icons.star_rounded,
          label: '+${widget.points}',
          color: QuizColors.goldDark,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: scrimAlpha),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.18),
              child: Opacity(
                opacity: cardOpacity,
                child: Transform.scale(
                  scale: cardScale,
                  child: _RewardCard(full: widget.full),
                ),
              ),
            ),
            if (widget.showTime) ...[
              flyingPill(
                const Alignment(-0.28, 0.14),
                const Alignment(-0.72, -0.86),
                _RewardPill(
                  icon: Icons.more_time_rounded,
                  label: '+${widget.seconds} dtk',
                  color: QuizColors.correct,
                ),
              ),
              flyingPill(
                const Alignment(0.28, 0.14),
                const Alignment(0.78, -0.86),
                pointsPill,
              ),
            ] else
              // Hanya poin (mode suara) → melesat ke atas-tengah.
              flyingPill(
                const Alignment(0, 0.14),
                const Alignment(0, -0.86),
                pointsPill,
              ),
          ],
        );
      },
    );
  }
}

/// Kartu hadiah bertekstur solid (ikon + headline) sebagai latar jelas.
class _RewardCard extends StatelessWidget {
  final bool full;

  const _RewardCard({required this.full});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuizColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: QuizColors.gold.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [QuizColors.gold, QuizColors.goldDark],
              ),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            full ? 'Benar! 🎉' : 'Benar sebagian! 👍',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: QuizColors.goldDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hadiah untukmu…',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// Pill hadiah kecil (ikon + angka) yang terbang ke HUD.
class _RewardPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
