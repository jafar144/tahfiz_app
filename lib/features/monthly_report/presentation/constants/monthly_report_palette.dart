import 'package:flutter/material.dart';

/// Warna bersama form penilaian bulanan dan rekap admin.
///
/// Urutan hasil target dibaca dari merah (kena hukuman) ke hijau (optimum)
/// sehingga form dan rekap memakai bahasa warna yang sama.
class MonthlyReportPalette {
  MonthlyReportPalette._();

  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const field = Color(0xFFF3F4F6);
  static const line = Color(0xFFE5E7EB);

  /// Tidak capai memakai jingga; baru menjadi merah bila masuk hukuman.
  static const notAchieved = Color(0xFFB54708);
  static const penalized = Color(0xFFB42318);
  static const excused = notAchieved;
  static const minimum = Color(0xFF0F766E);
  static const optimum = Color(0xFF2E7D32);
}
