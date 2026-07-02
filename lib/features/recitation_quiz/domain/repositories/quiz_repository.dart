import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';

abstract class QuizRepository {
  /// Susun [count] soal acak sesuai [settings] (juz terpilih + sambungan antar
  /// surah). Tiap soal: 1 ayat petunjuk → lanjutkan 1-3 ayat berikutnya.
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count,
    required QuizSettings settings,
  });

  /// Transkripsi audio lalu cocokkan dengan ayat jawaban.
  Future<Either<Failure, RecitationResult>> checkAnswer({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  });

  /// Simpan hasil sesi kuis (fondasi leaderboard).
  Future<Either<Failure, void>> saveAttempt({
    required int totalScore,
    required List<int> questionScores,
    required List<int> juz,
    required bool crossSurah,
  });
}
