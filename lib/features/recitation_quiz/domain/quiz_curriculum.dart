import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_tier.dart';

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

  /// Tingkatan leaderboard yang benar-benar memiliki paket soal berbeda.
  ///
  /// Beberapa kelas kurikulum dapat memakai cakupan kuis yang sama karena bank
  /// soal belum mencapai materi kelas tersebut. Cakupan yang identik hanya
  /// menghasilkan satu tingkatan dan memakai kelas pertama sebagai canonical.
  static List<QuizTier> get leaderboardTiers {
    final result = <QuizTier>[];
    final seenScopes = <String>{};

    for (final className in _curriculum.classesWithMemorization) {
      final scope = scopeFor(className);
      if (scope == null) continue;
      final fingerprint = _scopeFingerprint(scope);
      if (fingerprint == null || !seenScopes.add(fingerprint)) continue;

      final label = _tierLabel(className, scope);
      result.add(
        QuizTier(key: _tierKey(label), label: label, scopeClass: className),
      );
    }
    return List.unmodifiable(result);
  }

  /// Tingkatan canonical untuk cakupan kelas yang dipilih santri.
  ///
  /// Contoh: seluruh Takhossus Tsani–Akhir saat ini memiliki cakupan soal yang
  /// sama dengan Takhossus Awal, sehingga semuanya kembali ke tingkatan
  /// `Takhossus Awal`.
  static QuizTier? leaderboardTierFor(String? scopeClass) {
    final scope = scopeFor(scopeClass);
    if (scope == null) return null;
    final target = _scopeFingerprint(scope);
    if (target == null) return null;

    for (final tier in leaderboardTiers) {
      final tierScope = scopeFor(tier.scopeClass);
      if (tierScope != null && _scopeFingerprint(tierScope) == target) {
        return tier;
      }
    }
    return null;
  }

  static String? _scopeFingerprint(MemorizationScope scope) {
    final juz = scope.juz.where(QuizJuz.isSupported).toSet().toList()..sort();
    final surahs = scope.extraSurahs.toList()..sort();
    if (juz.isEmpty && surahs.isEmpty) return null;
    return 'j:${juz.join(',')}|s:${surahs.join(',')}';
  }

  static String _tierLabel(String className, MemorizationScope scope) {
    final juz = scope.juz.where(QuizJuz.isSupported).toSet();
    if (juz.length == 1 && juz.single == 30 && scope.extraSurahs.isEmpty) {
      return 'Juz 30';
    }
    return className;
  }

  static String _tierKey(String label) => label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

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
