import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/firebase_options.dart';
import 'package:khoirunnasyien/flavors/al_jauhar/app_config.dart';
import 'package:khoirunnasyien/flavors/al_jauhar/firebase_options.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/firebase_options.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/app_config.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/firebase_options.dart';

void main() {
  test('Al-Jauhar memiliki identitas, Firebase, dan aset terpisah', () {
    expect(alJauharAppConfig.flavor, 'al_jauhar');
    expect(alJauharAppConfig.appName, 'Tahfiz Al-Jauhar');
    expect(alJauharAppConfig.authEmailDomain, 'aljauhar.app');
    expect(alJauharAppConfig.logoAsset, contains('/al_jauhar/'));
    expect(alJauharAppConfig.syahadahLogoAsset, contains('/al_jauhar/'));
    expect(AlJauharFirebaseOptions.android.projectId, 'al-jauhar-app');
    expect({
      AlJauharFirebaseOptions.android.projectId,
      KhoirunnasyienFirebaseOptions.android.projectId,
      BarokatulQuranFirebaseOptions.android.projectId,
    }, hasLength(3));
  });

  test(
    'konfigurasi awal kelas, kelulusan, dan pembayaran mengikuti Khoirun',
    () {
      final actual = alJauharAppConfig.curriculum;
      final expected = khoirunnasyienAppConfig.curriculum;
      expect(actual.classNames, expected.classNames);
      expect(actual.classTypes, expected.classTypes);
      expect(actual.fiqihClassNames, expected.fiqihClassNames);
      expect(actual.firstFiqihEligibleClass, expected.firstFiqihEligibleClass);
      expect(
        actual.graduationMilestones.map(
          (item) => '${item.number}:${item.label}',
        ),
        expected.graduationMilestones.map(
          (item) => '${item.number}:${item.label}',
        ),
      );
      expect(
        alJauharAppConfig.payment.bankName,
        khoirunnasyienAppConfig.payment.bankName,
      );
      expect(
        alJauharAppConfig.payment.accountNumber,
        khoirunnasyienAppConfig.payment.accountNumber,
      );
      expect(
        alJauharAppConfig.payment.accountHolder,
        khoirunnasyienAppConfig.payment.accountHolder,
      );
      expect(alJauharAppConfig.payment.monthlyFee, 200000);
      expect(
        alJauharAppConfig.payment.monthlyFeeFor(gender: 'P', classType: 'Pagi'),
        200000,
      );
      expect(
        alJauharAppConfig.payment.firstSupportedPaymentPeriod,
        DateTime(2026, 4),
      );
    },
  );

  test('warna brand hijau hanya untuk Al-Jauhar, flavor lain tetap biru', () {
    if (FlavorFirebaseOptions.flavor == 'al_jauhar') {
      expect(kGreenBrand, isTrue);
      for (final color in [
        AppColors.primary,
        AppColors.secondary,
        AppColors.brand,
        AppColors.brand.shade700,
        AppColors.brandLight,
        AppColors.brandDeep.shade700,
      ]) {
        final hue = HSLColor.fromColor(color).hue;
        expect(hue, inInclusiveRange(90, 170), reason: '$color harus hijau');
      }
      expect(AppColors.brand, isNot(Colors.blue));
    } else {
      expect(kGreenBrand, isFalse);
      expect(AppColors.brand, Colors.blue);
      expect(AppColors.brandLight, Colors.lightBlue);
      expect(AppColors.brandDeep, Colors.indigo);
      expect(AppColors.primary, const Color.fromRGBO(30, 136, 229, 1));
    }
  });

  test('resolver background FCM mengikuti APP_FLAVOR Al-Jauhar', () {
    // Uji ini juga dijalankan dengan --dart-define=APP_FLAVOR=al_jauhar.
    if (FlavorFirebaseOptions.flavor != 'al_jauhar') return;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      FlavorFirebaseOptions.currentPlatform,
      AlJauharFirebaseOptions.android,
    );
  });
}
