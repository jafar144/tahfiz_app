import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_curriculum.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/app_config.dart';

void main() {
  setUpAll(() => AppConfig.configure(khoirunnasyienAppConfig));

  test('flavor exposes institution classes in their configured order', () {
    expect(AppConfig.current.flavor, 'khoirunnasyien');
    expect(AppConfig.current.curriculum.classNames.first, 'Tahsin Awwal');
    expect(AppConfig.current.curriculum.classNames.last, 'Takhossus Akhir');
  });

  test('quiz adapter reads the institution curriculum', () {
    expect(QuizCurriculum.canChallenge('Tahsin Awwal'), isFalse);
    expect(QuizCurriculum.classBelow('Takhossus Awal'), 'Pra Takhossus Akhir');

    final settings = QuizCurriculum.settingsFor(
      'Pra Takhossus Awal',
      QuizMode.voice,
    );
    expect(settings.juz, {30});
    expect(settings.extraSurahs, {77, 75, 74, 70, 69, 68});
  });

  test('fiqih classes only apply from Mutawassith upward', () {
    final curriculum = AppConfig.current.curriculum;

    expect(curriculum.fiqihClassNames, ['Fiqih 1', 'Fiqih 2', 'Fiqih 3']);
    expect(curriculum.isFiqihEligible('Tahsin Awwal'), isFalse);
    expect(curriculum.isFiqihEligible('Tahsin Akhir'), isFalse);
    expect(curriculum.isFiqihEligible('Mutawassith'), isTrue);
    expect(curriculum.isFiqihEligible('Takhossus Akhir'), isTrue);
    expect(
      curriculum.normalizeFiqihClass('Mutawassith', ' Fiqih 2 '),
      'Fiqih 2',
    );
    expect(curriculum.normalizeFiqihClass('Tahsin Akhir', 'Fiqih 1'), isNull);
    expect(curriculum.normalizeFiqihClass('Mutawassith', 'Fiqih 4'), isNull);
  });

  test('leaderboard exposes distinct quiz tiers, not curriculum classes', () {
    final tiers = QuizCurriculum.leaderboardTiers;

    expect(tiers.map((tier) => tier.label), [
      'Juz 30',
      'Pra Takhossus Awal',
      'Pra Takhossus Akhir',
      'Takhossus Awal',
    ]);
    expect(tiers.map((tier) => tier.key), [
      'juz_30',
      'pra_takhossus_awal',
      'pra_takhossus_akhir',
      'takhossus_awal',
    ]);
  });

  test('curriculum classes resolve to their canonical quiz tier', () {
    expect(QuizCurriculum.leaderboardTierFor('Mutawassith')?.label, 'Juz 30');
    expect(
      QuizCurriculum.leaderboardTierFor('Takhossus Tsalits')?.label,
      'Takhossus Awal',
    );
    expect(QuizCurriculum.leaderboardTierFor('Tahsin Akhir'), isNull);
  });
}
