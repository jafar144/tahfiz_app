import 'dart:math';

import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Halaman loading FULL-SCREEN bernuansa malam islami — satu-satunya gaya
/// loading di seluruh Tahfiz Arena (masuk peta Petualangan, membuka surah,
/// dan menyiapkan sesi Latihan/Tantangan) agar konsisten di mana pun.
///
/// [withBackground] false → tanpa langit sendiri (dipakai di dalam halaman
/// yang sudah punya latar malam, mis. area konten kuis).
class NightLoadingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBack;
  final VoidCallback? onBack;
  final bool withBackground;

  const NightLoadingPage({
    super.key,
    this.title = 'Sebentar ya…',
    this.subtitle = '',
    this.icon = Icons.auto_stories_rounded,
    this.showBack = false,
    this.onBack,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (withBackground) ...[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QuizColors.nightTop, QuizColors.nightBottom],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _LoadingSkyPainter()),
          ),
        ],
        if (showBack)
          Positioned(
            left: 12,
            top: 8,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingLoadingBadge(icon: icon),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(QuizColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lencana emas berdenyut (halo bernapas) di tengah halaman loading.
class _PulsingLoadingBadge extends StatefulWidget {
  final IconData icon;

  const _PulsingLoadingBadge({required this.icon});

  @override
  State<_PulsingLoadingBadge> createState() => _PulsingLoadingBadgeState();
}

class _PulsingLoadingBadgeState extends State<_PulsingLoadingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        return SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Halo emas yang membesar-mengecil MELUBER keluar footprint agar
              // teks di bawahnya tak ikut bergeser.
              Center(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Container(
                    width: 68 + 22 * t,
                    height: 68 + 22 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: QuizColors.gold.withValues(
                          alpha: 0.15 + 0.5 * (1 - t),
                        ),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [QuizColors.gold, QuizColors.goldDark],
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: QuizColors.gold.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: 32),
      ),
    );
  }
}

/// Bintang berkelip statis + bulan sabit untuk latar halaman loading.
class _LoadingSkyPainter extends CustomPainter {
  const _LoadingSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7); // seed tetap → pola stabil
    final star = Paint();

    final starCount = (size.height / 16).round();
    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.6 + rng.nextDouble() * 1.3;
      star.color = Colors.white.withValues(
        alpha: 0.20 + rng.nextDouble() * 0.45,
      );
      canvas.drawCircle(Offset(x, y), r, star);
    }

    // Bulan sabit di kanan atas.
    final moonCenter = Offset(size.width * 0.82, 64);
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moonCenter, radius: 26)),
      Path()..addOval(
        Rect.fromCircle(center: moonCenter.translate(11, -7), radius: 23),
      ),
    );
    canvas.drawPath(
      moon,
      Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingSkyPainter oldDelegate) => false;
}
