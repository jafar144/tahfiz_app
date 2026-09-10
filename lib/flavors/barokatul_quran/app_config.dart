import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/curriculum.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/firebase_options.dart';

final barokatulQuranAppConfig = AppConfig(
  flavor: 'barokatul_quran',
  appName: "Barokatul Qur'an",
  institutionName: "Barokatul Qur'an",
  logoAsset: 'assets/flavors/barokatul_quran/images/logo.png',
  syahadahLogoAsset: 'assets/flavors/barokatul_quran/images/logo_bg.png',
  functionsRegion: 'asia-southeast2',
  authEmailDomain: 'barokatulquran.app',
  // Nilai pembayaran sengaja eksplisit sebagai placeholder agar tidak
  // menampilkan rekening lembaga lain sebelum data Barokatul dikonfirmasi.
  payment: const InstitutionPaymentConfig(
    bankName: 'Belum dikonfigurasi',
    accountNumber: '-',
    accountHolder: '-',
  ),
  curriculum: barokatulQuranCurriculum,
  firebaseOptionsProvider: () => BarokatulQuranFirebaseOptions.currentPlatform,
);
