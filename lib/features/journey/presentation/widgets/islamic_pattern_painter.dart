import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pola geometris islami (bintang Rub el Hizb — dua persegi bertumpuk)
/// yang diulang sebagai dekorasi latar halus pada banner.
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;

  IslamicPatternPainter({
    required this.color,
    this.spacing = 46,
    this.radius = 9,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = -spacing / 2; y <= size.height + spacing; y += spacing) {
      for (double x = -spacing / 2; x <= size.width + spacing; x += spacing) {
        final center = Offset(x, y);
        canvas.drawPath(_square(center, radius, 0), paint);
        canvas.drawPath(_square(center, radius, math.pi / 4), paint);
      }
    }
  }

  Path _square(Offset center, double r, double rotation) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = rotation + i * math.pi / 2 + math.pi / 4;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.spacing != spacing ||
      oldDelegate.radius != radius;
}
