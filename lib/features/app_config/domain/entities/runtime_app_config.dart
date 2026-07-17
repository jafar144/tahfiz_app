import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';

class RuntimeAppConfig {
  final Map<AppFeature, bool> features;

  const RuntimeAppConfig({required this.features});

  factory RuntimeAppConfig.defaults() {
    return RuntimeAppConfig(
      features: {
        for (final feature in AppFeature.values)
          feature: feature.defaultEnabled,
      },
    );
  }

  factory RuntimeAppConfig.fromMap(Map<String, dynamic>? map) {
    final rawFeatures = map?['features'];
    final featureMap = rawFeatures is Map
        ? Map<String, dynamic>.from(rawFeatures)
        : const <String, dynamic>{};

    return RuntimeAppConfig(
      features: {
        for (final feature in AppFeature.values)
          feature: featureMap[feature.key] is bool
              ? featureMap[feature.key] as bool
              : feature.defaultEnabled,
      },
    );
  }

  bool isEnabled(AppFeature feature) {
    return features[feature] ?? feature.defaultEnabled;
  }

  RuntimeAppConfig withFeature(AppFeature feature, bool enabled) {
    return RuntimeAppConfig(features: {...features, feature: enabled});
  }

  Map<String, dynamic> toMap() {
    return {
      'features': {
        for (final feature in AppFeature.values)
          feature.key: isEnabled(feature),
      },
    };
  }
}
