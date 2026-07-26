import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/curriculum.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/firebase_options.dart';

final khoirunnasyienAppConfig = AppConfig(
  flavor: 'khoirunnasyien',
  appName: 'Khoirunnasyien',
  institutionName: 'Khoirunnasyien',
  logoAsset: 'assets/flavors/khoirunnasyien/images/logo.png',
  syahadahLogoAsset: 'assets/flavors/khoirunnasyien/images/logo_bg.png',
  functionsRegion: 'asia-southeast2',
  authEmailDomain: 'khoirunnasyien.app',
  payment: InstitutionPaymentConfig(
    bankName: 'BSI',
    accountNumber: '7117245448',
    accountHolder: 'Fahmi Ramdani',
  ),
  curriculum: khoirunnasyienCurriculum,
  firebaseOptionsProvider: () => KhoirunnasyienFirebaseOptions.currentPlatform,
);
