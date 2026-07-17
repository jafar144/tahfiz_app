import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Satu baris peringkat pada papan juara bulanan.
class LeaderboardEntry {
  final String userId;
  final String name;
  final String role;

  /// Skor terbaik user pada bulan berjalan (0..100).
  final int bestScore;

  /// Kapan skor terbaik dicapai — dipakai sebagai tie-break
  /// (skor sama → yang lebih dulu mencapainya di atas).
  final DateTime? bestAt;

  /// Jumlah sesi kuis yang diselesaikan bulan ini.
  final int playCount;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.bestScore,
    this.bestAt,
    this.playCount = 0,
  });
}

/// Snapshot papan juara satu bulan untuk satu mode.
class MonthlyLeaderboard {
  /// Mode papan ini (suara / pilihan) — leaderboard dipisah per mode karena
  /// skalanya berbeda dan tidak bisa dibandingkan.
  final QuizMode mode;

  /// Kunci bulan, format `yyyy-MM` (mis. `2026-07`).
  final String monthKey;

  /// Peringkat teratas sesuai batas query, sudah terurut.
  final List<LeaderboardEntry> entries;

  /// Entri milik user saat ini (null bila belum pernah main bulan ini).
  final LeaderboardEntry? myEntry;

  /// Peringkat user saat ini (1-based); null bila belum pernah main.
  final int? myRank;

  const MonthlyLeaderboard({
    required this.mode,
    required this.monthKey,
    required this.entries,
    this.myEntry,
    this.myRank,
  });

  bool get isEmpty => entries.isEmpty;
}
