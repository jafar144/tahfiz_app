import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/runtime_app_config.dart';

enum AppConfigStatus { initial, loading, ready, failure }

class AppConfigState {
  final AppConfigStatus status;
  final RuntimeAppConfig config;
  final Set<AppFeature> updatingFeatures;
  final String? errorMessage;

  AppConfigState({
    this.status = AppConfigStatus.initial,
    RuntimeAppConfig? config,
    this.updatingFeatures = const {},
    this.errorMessage,
  }) : config = config ?? RuntimeAppConfig.defaults();

  bool isUpdating(AppFeature feature) => updatingFeatures.contains(feature);
}
