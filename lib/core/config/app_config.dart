import 'package:firebase_core/firebase_core.dart';
import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';

typedef FirebaseOptionsProvider = FirebaseOptions Function();

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
  final InstitutionCurriculum curriculum;
  final FirebaseOptionsProvider firebaseOptionsProvider;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.institutionName,
    required this.logoAsset,
    required this.syahadahLogoAsset,
    required this.functionsRegion,
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
