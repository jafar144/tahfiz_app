import 'package:khoirunnasyien/core/config/app_config.dart';

class AppConstants {
  static List<String> get santriClasses =>
      AppConfig.current.curriculum.classNames;

  static List<String> get classTypes => AppConfig.current.curriculum.classTypes;

  static const int sessionBufferMinutes = 30;
}
