import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Hasil satu soal setelah dikerjakan.
///
/// Mode suara: bisa lewat 1-2 percobaan; [score] 0..100.
/// Mode pilihan: satu kali jawab; [score] = poin (0 bila salah, 10/15/20 bila
/// benar sesuai jumlah ayat).
class QuizAnswer {
  final int questionIndex;

  /// Skor/poin akhir soal ini yang ikut dihitung ke total.
  final int score;

  /// Berapa kali direkam (mode suara: 1 atau 2; mode pilihan: selalu 1).
  final int attempts;

  /// True bila lolos/benar.
  final bool passed;

  /// Hasil pemeriksaan percobaan terbaik — mode suara saja (untuk koreksi).
  final RecitationResult? bestResult;

  const QuizAnswer({
    required this.questionIndex,
    required this.score,
    required this.attempts,
    required this.passed,
    this.bestResult,
  });
}

/// Rekap keseluruhan sesi kuis.
class QuizResult {
  final List<QuizAnswer> answers;
  final int questionCount;
  final QuizMode mode;

  const QuizResult({
    required this.answers,
    required this.questionCount,
    this.mode = QuizMode.voice,
  });

  /// Jumlah semua skor/poin soal.
  int get totalPoints => answers.fold<int>(0, (acc, a) => acc + a.score);

  /// Nilai rata-rata (0..100) — dipakai mode suara.
  int get averageScore {
    if (questionCount == 0) return 0;
    return (totalPoints / questionCount).round();
  }

  /// Skor yang masuk leaderboard:
  /// - suara  : rata-rata 0..100
  /// - pilihan: total poin terkumpul
  int get leaderboardScore =>
      mode.isChoice ? totalPoints : averageScore;

  List<int> get scores => answers.map((a) => a.score).toList();

  int get passedCount => answers.where((a) => a.passed).length;
}
