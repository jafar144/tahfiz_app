import 'package:khoirunnasyien/core/error/failure.dart';

/// Alasan sesi kuis tidak bisa dimulai.
enum QuizBlockReason {
  /// Sedang ada pengguna lain yang bermain (lock 1-user).
  busy,

  /// Kuota transkripsi Whisper sedang penuh (429) — jeda sejenak.
  whisperLimit,

  /// Energi pengguna habis.
  noEnergy,

  /// Jatah Tantangan hari ini (mode terkait) sudah terpakai.
  dailyLimit,

  /// Sebab lain (jaringan/server).
  unknown,
}

/// Kegagalan memulai sesi kuis dengan [reason] yang bisa dipetakan ke UI.
class QuizBlockedFailure extends Failure {
  final QuizBlockReason reason;

  const QuizBlockedFailure(this.reason, super.message);
}
