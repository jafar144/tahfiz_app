import 'package:firebase_core/firebase_core.dart';
import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';

typedef FirebaseOptionsProvider = FirebaseOptions Function();

class InstitutionPaymentConfig {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final int monthlyFee;
  final int? femaleMorningMonthlyFee;
  final int firstSupportedPaymentYear;
  final int firstSupportedPaymentMonth;

  const InstitutionPaymentConfig({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.monthlyFee = 200000,
    this.femaleMorningMonthlyFee = 100000,
    this.firstSupportedPaymentYear = 2026,
    this.firstSupportedPaymentMonth = 2,
  });

  String get transferInstruction =>
      'Pembayaran bisa via transfer: Bank $bankName '
      '$accountNumber a.n. $accountHolder';

  DateTime get firstSupportedPaymentPeriod =>
      DateTime(firstSupportedPaymentYear, firstSupportedPaymentMonth);

  int monthlyFeeFor({required String gender, required String? classType}) {
    final isFemaleMorning =
        gender.toUpperCase() == 'P' && classType?.toLowerCase() == 'pagi';
    return isFemaleMorning && femaleMorningMonthlyFee != null
        ? femaleMorningMonthlyFee!
        : monthlyFee;
  }
}

/// Konfigurasi runtime untuk satu hasil build white-label.
///
/// Nilainya dipasang sekali di composition root `main_<flavor>.dart`, sehingga
/// kode fitur tidak perlu mengetahui flavor yang sedang dibangun.
class AppConfig {
  static AppConfig? _current;

  final String flavor;
  final String appName;
  final String institutionName;
  final String logoAsset;
  final String syahadahLogoAsset;
  final String functionsRegion;
  final String authEmailDomain;
  final bool notificationsEnabled;
  final InstitutionPaymentConfig payment;
  final InstitutionCurriculum curriculum;
  final FirebaseOptionsProvider firebaseOptionsProvider;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.institutionName,
    required this.logoAsset,
    required this.syahadahLogoAsset,
    required this.functionsRegion,
    required this.authEmailDomain,
    this.notificationsEnabled = true,
    required this.payment,
    required this.curriculum,
    required this.firebaseOptionsProvider,
  });

  static AppConfig get current {
    final config = _current;
    if (config == null) {
      throw StateError(
        'AppConfig belum dikonfigurasi. Jalankan aplikasi melalui '
        'main_<flavor>.dart.',
      );
    }
    return config;
  }

  /// Null sebelum bootstrap; dipakai utility murni agar tetap dapat diuji.
  static AppConfig? get configured => _current;

  static void configure(AppConfig config) {
    final current = _current;
    if (current != null && current.flavor != config.flavor) {
      throw StateError(
        'AppConfig sudah dikonfigurasi untuk flavor ${current.flavor}.',
      );
    }
    _current = config;
  }
}
