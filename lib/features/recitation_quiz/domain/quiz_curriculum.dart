import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';

/// Adapter kurikulum lembaga untuk kebutuhan fitur Tantangan.
///
/// Data kurikulum tidak didefinisikan di fitur kuis. Setiap flavor menyuplai
/// [InstitutionCurriculum] sendiri dan adapter ini hanya menerjemahkannya
/// menjadi [QuizSettings].
class QuizCurriculum {
  QuizCurriculum._();

  static InstitutionCurriculum get _curriculum => AppConfig.current.curriculum;

  static MemorizationScope? scopeFor(String? kelas) =>
      _curriculum.scopeFor(kelas);

  static bool canChallenge(String? kelas) => scopeFor(kelas) != null;

  static String? classBelow(String? kelas) => _curriculum.classBelow(kelas);

  static List<String> get rankableClasses =>
      _curriculum.classesWithMemorization;

  static QuizSettings settingsFor(
    String kelas,
    QuizMode mode, {
    QuizDifficulty difficulty = QuizDifficulty.medium,
  }) {
    final scope = scopeFor(kelas);
    if (scope == null) {
      throw ArgumentError('Kelas "$kelas" tidak punya paket Tantangan.');
    }
    return QuizSettings(
      mode: mode,
      difficulty: difficulty,
      juz: scope.juz.toSet(),
      extraSurahs: scope.extraSurahs,
    );
  }
}
