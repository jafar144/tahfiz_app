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
    expect(
      AppConfig.current.curriculum.classNames.last,
      'Takhossus Akhir',
    );
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
}
