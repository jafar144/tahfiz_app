import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Jenis sesi Tahfiz Arena.
enum QuizSessionKind { practice, challenge }

/// Aturan lintas mode serta perbedaan Latihan dan Tantangan.
///
/// LATIHAN:
/// - mode dan cakupan dipilih santri;
/// - memakai energi mingguan;
/// - hasil tidak ditulis ke histori/leaderboard.
///
/// TANTANGAN:
/// - mode dan cakupan dikunci oleh kurikulum kelas;
/// - memakai kuota harian terpisah untuk Suara dan Pilihan;
/// - hasil ditulis ke histori dan leaderboard tingkatan kuis.
///
/// Jumlah energi/kuota adalah otoritas Cloud Functions. File ini hanya memuat
/// perilaku client yang menjadi bagian dari gameplay.
class QuizSessionRules {
  QuizSessionRules._();

  /// Master switch energi, kuota, dan lock sesi. Admin selalu bypass.
  static const bool enforceServerGate = true;

  /// Mode Suara memegang lock karena memakai kuota API transkripsi.
  static bool requiresServerLock(QuizMode mode) => mode.isVoice;

  static bool storesResult(QuizSessionKind kind) =>
      kind == QuizSessionKind.challenge;

  /// Perpanjangan lock harus lebih singkat daripada lease server (2 menit).
  static const Duration heartbeatInterval = Duration(seconds: 40);

  static const int leaderboardLimit = 10;
}
