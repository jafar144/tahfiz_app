import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/runtime_app_config.dart';

abstract interface class AppConfigRepository {
  Stream<RuntimeAppConfig> watch();

  Future<void> setFeatureEnabled(AppFeature feature, bool enabled);
}
