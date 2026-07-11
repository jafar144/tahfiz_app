import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';

/// Data animasi "menyusul" pasca-Tantangan: peringkat user SEBELUM skor baru
/// tercatat vs SESUDAH, plus snapshot papan juara terbaru untuk digambar.
///
/// Hanya dibuat bila peringkat benar-benar NAIK (atau baru masuk papan);
/// selain itu alur langsung ke layar hasil tanpa animasi.
class QuizRankReveal {
  /// Peringkat sebelum sesi ini (1-based); null = belum pernah masuk papan
  /// bulan ini (skor pertama).
  final int? fromRank;

  /// Peringkat setelah skor baru tersimpan (1-based).
  final int toRank;

  /// Skor terbaik BARU yang barusan tercatat.
  final int newBest;

  /// Skor terbaik lama; null bila belum pernah punya skor bulan ini.
  final int? previousBest;

  /// Papan juara SETELAH skor tersimpan, terurut (maks 10 teratas).
  final List<LeaderboardEntry> entries;

  /// UID user saat ini (untuk menandai baris "Kamu" di [entries]).
  final String myUserId;

  const QuizRankReveal({
    required this.fromRank,
    required this.toRank,
    required this.newBest,
    this.previousBest,
    required this.entries,
    required this.myUserId,
  });

  /// True bila posisi BARU user tampak di papan → animasi memanjat daftar.
  /// False (naik peringkat tapi masih di luar top-10) → varian angka membesar.
  bool get climbsVisibleBoard =>
      toRank >= 1 &&
      toRank <= entries.length &&
      entries[toRank - 1].userId == myUserId;

  /// Jumlah teman yang disusul; 0 bila baru masuk papan (tak diketahui).
  int get overtakenCount => fromRank == null ? 0 : fromRank! - toRank;

  /// True bila ini skor pertama user di papan bulan ini.
  bool get isNewEntry => fromRank == null;
}
