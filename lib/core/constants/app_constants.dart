import 'package:khoirunnasyien/core/config/app_config.dart';

class AppConstants {
  static List<String> get santriClasses =>
      AppConfig.current.curriculum.classNames;

  static List<String> get classTypes => AppConfig.current.curriculum.classTypes;

  static List<String> get fiqihClasses =>
      AppConfig.current.curriculum.fiqihClassNames;

  static bool isFiqihEligible(String? santriClass) =>
      AppConfig.current.curriculum.isFiqihEligible(santriClass);

  static const int sessionBufferMinutes = 30;
}
