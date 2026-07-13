/// Tingkat kesulitan sesi sekaligus label kesulitan setiap soal inti.
enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyX on QuizDifficulty {
  String get key => switch (this) {
    QuizDifficulty.easy => 'easy',
    QuizDifficulty.medium => 'medium',
    QuizDifficulty.hard => 'hard',
  };

  String get label => switch (this) {
    QuizDifficulty.easy => 'Mudah',
    QuizDifficulty.medium => 'Sedang',
    QuizDifficulty.hard => 'Sulit',
  };

  static QuizDifficulty fromKey(String? key) => switch (key) {
    'easy' => QuizDifficulty.easy,
    'hard' => QuizDifficulty.hard,
    _ => QuizDifficulty.medium,
  };
}
