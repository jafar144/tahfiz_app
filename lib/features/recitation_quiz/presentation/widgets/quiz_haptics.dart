import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Umpan balik getaran bergaya Duolingo untuk kuis: setiap ketukan opsi,
/// tombol aksi, dan hasil benar/salah punya "rasa" getarnya sendiri.
///
/// Pakai package `vibration` (getar berbasis DURASI) supaya terasa lebih
/// "tebal" daripada `HapticFeedback.heavyImpact()` bawaan Flutter, yang di
/// banyak device Android cuma preset getar tipis.
///
/// PENTING: gate-nya `hasVibrator()`, BUKAN `hasAmplitudeControl()`. Banyak HP
/// (mid-range/budget) melaporkan `hasAmplitudeControl = false` tapi tetap bisa
/// getar berbasis durasi — dan itulah yang bikin rasa "Duolingo". Amplitude
/// cuma dipakai sebagai bonus kalau memang didukung. Fallback ke
/// `HapticFeedback` hanya kalau device benar-benar tak punya motor getar.
abstract final class QuizHaptics {
  static Future<bool>? _hasVibrator;
  static Future<bool>? _hasAmplitude;

  static Future<bool> get _canVibrate =>
      _hasVibrator ??= Vibration.hasVibrator().catchError((_) => false);

  static Future<bool> get _canAmplitude =>
      _hasAmplitude ??= Vibration.hasAmplitudeControl().catchError((_) => false);

  static Future<void> _vibrate({
    required int duration,
    required int amplitude,
  }) async {
    if (!await _canVibrate) {
      await HapticFeedback.heavyImpact();
      return;
    }
    if (await _canAmplitude) {
      await Vibration.vibrate(duration: duration, amplitude: amplitude);
    } else {
      // Tanpa amplitude control: getar durasi penuh tetap terasa tebal.
      await Vibration.vibrate(duration: duration);
    }
  }

  /// Ketukan saat memilih opsi / chip / jawaban.
  static void select() => _vibrate(duration: 35, amplitude: 190);

  /// Ketukan untuk tombol aksi utama (Jawab, Rekam, Lanjut, Mulai).
  static void tap() => _vibrate(duration: 45, amplitude: 230);

  /// Ketukan untuk aksi sekunder (hapus pilihan, tombol kecil).
  static void light() => _vibrate(duration: 25, amplitude: 130);

  /// Getaran mantap saat jawaban BENAR.
  static void correct() => _vibrate(duration: 70, amplitude: 255);

  /// Pola getar "salah" khas Duolingo: dua ketukan tegas dengan jeda lebih lama.
  static Future<void> wrong() async {
    if (!await _canVibrate) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));
      await HapticFeedback.heavyImpact();
      return;
    }
    if (await _canAmplitude) {
      await Vibration.vibrate(
        pattern: [0, 90, 500, 90],
        intensities: [0, 255, 0, 255],
      );
    } else {
      // Pola tanpa intensitas: tetap dua ketukan tegas dengan jeda.
      await Vibration.vibrate(pattern: [0, 90, 500, 90]);
    }
  }
}
