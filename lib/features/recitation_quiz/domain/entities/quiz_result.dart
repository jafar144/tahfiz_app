import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';

/// Hasil satu soal setelah dikerjakan (bisa lewat 1 atau 2 percobaan).
class QuizAnswer {
  final int questionIndex;

  /// Skor akhir soal ini (0..100) yang ikut dihitung ke total.
  final int score;

  /// Berapa kali direkam (1 atau 2).
  final int attempts;

  /// True bila lolos (≥80% di salah satu percobaan). False bila gagal 2x.
  final bool passed;

  /// Hasil pemeriksaan percobaan terbaik — untuk menampilkan koreksi.
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

  const QuizResult({required this.answers, required this.questionCount});

  /// Total nilai (0..100) = Σ skor tiap soal ÷ jumlah soal.
  int get totalScore {
    if (questionCount == 0) return 0;
    final sum = answers.fold<int>(0, (acc, a) => acc + a.score);
    return (sum / questionCount).round();
  }

  List<int> get scores => answers.map((a) => a.score).toList();

  int get passedCount => answers.where((a) => a.passed).length;
}
