enum AppFeature { tahfizArena }

extension AppFeatureX on AppFeature {
  String get key => switch (this) {
    AppFeature.tahfizArena => 'tahfiz_arena',
  };

  String get label => switch (this) {
    AppFeature.tahfizArena => 'Tahfiz Arena',
  };

  bool get defaultEnabled => switch (this) {
    AppFeature.tahfizArena => true,
  };
}
