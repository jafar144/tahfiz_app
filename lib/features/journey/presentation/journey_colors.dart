import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';

/// Palet bertema islami untuk fitur perjalanan tahfiz (biru primary + emas).
class JourneyColors {
  const JourneyColors._();

  // Biru selaras dengan primary app (dipakai di tombol, dll).
  static const primaryDeep = Color(0xFF0D47A1);
  static const primaryMid = AppColors.primary;
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);
  static const sand = Color(0xFFF5EFE0);
  static const sandDark = Color(0xFFEDE4CC);
  static const sage = Color(0xFF6B8F71);
  static const charcoal = Color(0xFF2D2D2D);
  static const muted = Color(0xFF8A9BA3);
  static const lockedBg = Color(0xFFD0D8DC);

  /// Warna aksen utama untuk status tertentu.
  static Color accentFor(JourneyStatus status) => switch (status) {
        JourneyStatus.completed => gold,
        JourneyStatus.active => primaryDeep,
        JourneyStatus.locked => muted,
      };
}
