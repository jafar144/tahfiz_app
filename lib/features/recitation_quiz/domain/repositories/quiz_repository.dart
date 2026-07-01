import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';

abstract class QuizRepository {
  /// Susun [count] soal acak dari Juz 30 (tebak ayat lanjutan).
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({int count});

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
  });
}
