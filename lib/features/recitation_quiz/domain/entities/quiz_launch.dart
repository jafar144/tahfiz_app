import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Parameter peluncuran halaman kuis dari Tahfiz Arena.
///
/// `null` (tanpa extra) = mode LATIHAN (practice): santri bebas mengatur juz &
/// mode lewat layar intro, hasil TIDAK disimpan.
///
/// Instance kelas ini = mode TANTANGAN (challenge): mode & cakupan dikunci
/// sesuai kurikulum kelas, langsung mulai tanpa intro, hasil disimpan ke
/// leaderboard kelas. Hanya untuk santri, 1x per hari per mode.
class QuizLaunch {
  /// Mode permainan yang dipilih di lembar Tantangan (suara / pilihan).
  final QuizMode mode;

  final QuizDifficulty difficulty;

  /// Kelas ASLI santri — dipakai sebagai kelas leaderboard (santri selalu
  /// bersaing di papan kelasnya sendiri, walau memilih cakupan kelas bawah).
  final String ownKelas;

  /// Kelas CAKUPAN soal yang dipilih (kelas sendiri, atau 1 kelas di bawah).
  final String scopeKelas;

  const QuizLaunch({
    required this.mode,
    this.difficulty = QuizDifficulty.medium,
    required this.ownKelas,
    required this.scopeKelas,
  });
}
