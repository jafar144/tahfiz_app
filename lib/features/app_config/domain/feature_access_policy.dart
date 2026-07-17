import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/runtime_app_config.dart';

enum AppFeatureAccess { enabled, unavailable, hidden }

AppFeatureAccess resolveAppFeatureAccess({
  required RuntimeAppConfig config,
  required AppFeature feature,
  required UserRole role,
}) {
  if (config.isEnabled(feature) || role == UserRole.admin) {
    return AppFeatureAccess.enabled;
  }

  return switch (role) {
    UserRole.asatidz => AppFeatureAccess.hidden,
    UserRole.santri => AppFeatureAccess.unavailable,
    UserRole.admin => AppFeatureAccess.enabled,
  };
}
