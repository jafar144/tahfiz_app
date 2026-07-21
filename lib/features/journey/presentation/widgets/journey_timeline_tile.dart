import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';
import 'package:khoirunnasyien/features/journey/presentation/journey_colors.dart';

/// Satu baris pada peta perjalanan: rel (node + garis penghubung) + kartu tingkat.
class JourneyTimelineTile extends StatelessWidget {
  final JourneyLevel level;
  final int total;
  final bool isLast;

  /// Apakah garis penghubung ke tile di bawahnya (tingkat lebih rendah)
  /// sudah ditempuh (emas solid) atau belum (putus-putus).
  final bool connectorDone;
  final VoidCallback onTap;

  const JourneyTimelineTile({
    super.key,
    required this.level,
    required this.total,
    required this.isLast,
    required this.connectorDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                _buildNode(),
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _ConnectorPainter(done: connectorDone),
                      size: const Size(56, double.infinity),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22, top: 2),
              child: _buildCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode() {
    switch (level.status) {
      case JourneyStatus.completed:
        return _NodeCircle(
          gradient: const [JourneyColors.gold, JourneyColors.goldLight],
          icon: level.icon,
          iconColor: JourneyColors.primaryDeep,
          badge: _checkBadge(),
        );
      case JourneyStatus.active:
        return _NodeCircle(
          gradient: const [JourneyColors.primaryDeep, JourneyColors.primaryMid],
          icon: level.icon,
          iconColor: Colors.white,
          ring: true,
          glow: true,
        );
      case JourneyStatus.locked:
        return const _NodeCircle(
          gradient: [JourneyColors.lockedBg, JourneyColors.lockedBg],
          icon: Icons.lock_rounded,
          iconColor: JourneyColors.muted,
        );
    }
  }

  Widget _checkBadge() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: JourneyColors.sage,
        shape: BoxShape.circle,
        border: Border.all(color: JourneyColors.sand, width: 2),
      ),
      child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
    );
  }

  Widget _buildCard() {
    final isActive = level.isActive;
    final isLocked = level.isLocked;

    final (
      String eyebrow,
      IconData eyebrowIcon,
      Color eyebrowColor,
    ) = switch (level.status) {
      JourneyStatus.completed => (
        'SELESAI',
        Icons.verified_rounded,
        JourneyColors.sage,
      ),
      JourneyStatus.active => (
        'SEDANG DIJALANI',
        Icons.play_arrow_rounded,
        JourneyColors.gold,
      ),
      JourneyStatus.locked => (
        'TERKUNCI',
        Icons.lock_outline_rounded,
        JourneyColors.muted,
      ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLocked ? Colors.white.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? JourneyColors.gold : JourneyColors.sandDark,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color:
                        (isActive ? JourneyColors.gold : JourneyColors.charcoal)
                            .withValues(alpha: isActive ? 0.15 : 0.05),
                    blurRadius: isActive ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(eyebrowIcon, size: 12, color: eyebrowColor),
                const SizedBox(width: 4),
                Text(
                  eyebrow,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: eyebrowColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${level.number}/$total',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: JourneyColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              level.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isLocked ? JourneyColors.muted : JourneyColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level.description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: JourneyColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final Color iconColor;
  final bool ring;
  final bool glow;
  final Widget? badge;

  const _NodeCircle({
    required this.gradient,
    required this.icon,
    required this.iconColor,
    this.ring = false,
    this.glow = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: ring
                  ? Border.all(color: JourneyColors.gold, width: 2.5)
                  : null,
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: JourneyColors.gold.withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          if (badge != null) Positioned(bottom: -2, right: -2, child: badge!),
        ],
      ),
    );
  }
}

/// Garis penghubung antar node: emas solid (selesai) atau putus-putus (belum).
class _ConnectorPainter extends CustomPainter {
  final bool done;
  _ConnectorPainter({required this.done});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = done ? JourneyColors.gold : JourneyColors.lockedBg;

    if (done) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    } else {
      const dash = 5.0;
      const gap = 6.0;
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + dash).clamp(0, size.height)),
          paint,
        );
        y += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.done != done;
}
