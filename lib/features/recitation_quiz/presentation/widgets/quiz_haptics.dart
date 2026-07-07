import 'package:flutter/services.dart';

/// Umpan balik getaran bergaya Duolingo untuk kuis: setiap ketukan opsi,
/// tombol aksi, dan hasil benar/salah punya "rasa" getarnya sendiri.
abstract final class QuizHaptics {
  /// Ketukan saat memilih opsi / chip / jawaban.
  static void select() => HapticFeedback.heavyImpact();

  /// Ketukan untuk tombol aksi utama (Jawab, Rekam, Lanjut, Mulai).
  static void tap() => HapticFeedback.heavyImpact();

  /// Ketukan untuk aksi sekunder (hapus pilihan, tombol kecil).
  static void light() => HapticFeedback.heavyImpact();

  /// Getaran mantap saat jawaban BENAR.
  static void correct() => HapticFeedback.heavyImpact();

  /// Pola getar "salah" khas Duolingo: dua ketukan tegas dengan jeda lebih lama.
  static Future<void> wrong() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 500));
    await HapticFeedback.heavyImpact();
  }
}
