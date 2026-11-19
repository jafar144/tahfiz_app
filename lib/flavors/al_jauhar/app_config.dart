import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/flavors/al_jauhar/curriculum.dart';
import 'package:khoirunnasyien/flavors/al_jauhar/firebase_options.dart';

final alJauharAppConfig = AppConfig(
  flavor: 'al_jauhar',
  appName: 'Tahfiz Al-Jauhar',
  institutionName: 'Al-Jauhar',
  logoAsset: 'assets/flavors/al_jauhar/images/logo.png',
  syahadahLogoAsset: 'assets/flavors/al_jauhar/images/logo_bg.png',
  functionsRegion: 'asia-southeast2',
  authEmailDomain: 'aljauhar.app',
  // Sementara mengikuti Khoirunnasyien sesuai permintaan pemilik.
  payment: const InstitutionPaymentConfig(
    bankName: 'BSI',
    accountNumber: '7117245448',
    accountHolder: 'Fahmi Ramdani',
    monthlyFee: 200000,
    femaleMorningMonthlyFee: null,
    firstSupportedPaymentYear: 2026,
    firstSupportedPaymentMonth: 4,
  ),
  curriculum: alJauharCurriculum,
  firebaseOptionsProvider: () => AlJauharFirebaseOptions.currentPlatform,
);
