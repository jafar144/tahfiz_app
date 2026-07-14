import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_difficulty_rules.dart';

/// Hasil satu soal setelah dikerjakan.
///
/// Mode suara: bisa lewat 1-2 percobaan; [score] 0..100.
/// Mode pilihan: satu kali jawab; [score] = poin (0 bila salah, 10/14/18 bila
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

  /// Poin bonus soal bonus/trivia yang tidak dicampur ke poin utama.
  final int bonusScore;

  const QuizAnswer({
    required this.questionIndex,
    required this.score,
    required this.attempts,
    required this.passed,
    this.bestResult,
    this.bonusScore = 0,
  });

  /// Tambahkan poin bonus baru tanpa menghapus bonus cepat yang sudah didapat.
  QuizAnswer withBonus(int bonus) => QuizAnswer(
    questionIndex: questionIndex,
    score: score,
    attempts: attempts,
    passed: passed,
    bestResult: bestResult,
    bonusScore: bonusScore + bonus,
  );
}

/// Rekap keseluruhan sesi kuis.
class QuizResult {
  final List<QuizAnswer> answers;
  final int questionCount;
  final QuizMode mode;
  final QuizDifficulty difficulty;

  const QuizResult({
    required this.answers,
    required this.questionCount,
    this.mode = QuizMode.voice,
    this.difficulty = QuizDifficulty.easy,
  });

  /// Jumlah semua skor/poin soal.
  int get totalPoints => answers.fold<int>(0, (acc, a) => acc + a.score);

  /// Nilai rata-rata (0..100) — dipakai mode suara.
  int get averageScore {
    if (questionCount == 0) return 0;
    return (totalPoints / questionCount).round();
  }

  /// Total poin bonus yang dipisah dari poin utama.
  int get totalBonus => answers.fold<int>(0, (acc, a) => acc + a.bonusScore);

  /// Poin utama yang ditampilkan di layar hasil.
  /// Mode suara memakai nilai rata-rata bacaan; mode pilihan memakai total poin.
  int get resultPoints => mode.isChoice ? totalPoints : averageScore;

  double get modeMultiplier => QuizDifficultyRules.modeScoreMultiplier(mode);

  double get difficultyMultiplier =>
      QuizDifficultyRules.scoreMultiplier(difficulty);

  double get scoreMultiplier => modeMultiplier * difficultyMultiplier;

  double get xpMultiplier => QuizDifficultyRules.xpMultiplier(mode, difficulty);

  /// Skor dasar + bonus setelah multiplier kesulitan.
  int get finalScore => ((resultPoints + totalBonus) * scoreMultiplier).round();

  /// XP muncul setelah seluruh multiplier poin selesai diterapkan.
  int get earnedXp => (finalScore / 10).round();

  /// Skor yang masuk leaderboard:
  /// - suara  : rata-rata akurasi (0..100) + total poin bonus
  /// - pilihan: total poin terkumpul + bonus
  int get leaderboardScore => finalScore;

  List<int> get scores => answers.map((a) => a.score).toList();

  int get passedCount => answers.where((a) => a.passed).length;
}
