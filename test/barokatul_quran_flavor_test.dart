import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/app_config.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/firebase_options.dart';

void main() {
  test('Barokatul Qur\'an memakai identitas flavor dan Firebase terpisah', () {
    expect(barokatulQuranAppConfig.flavor, 'barokatul_quran');
    expect(barokatulQuranAppConfig.appName, "Barokatul Qur'an");
    expect(BarokatulQuranFirebaseOptions.android.projectId, 'barokatul-apps');
    expect(
      BarokatulQuranFirebaseOptions.android.appId,
      '1:406302789936:android:55bdab2b4cd5201d80f8f5',
    );
  });

  test('kurikulum awal aman dipakai sebelum konfigurasi final', () {
    final curriculum = barokatulQuranAppConfig.curriculum;

    expect(curriculum.classNames, isNotEmpty);
    expect(curriculum.classTypes, isNotEmpty);
    expect(curriculum.classesWithMemorization, contains('Tahfiz'));
  });
}
