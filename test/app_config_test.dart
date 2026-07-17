import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/runtime_app_config.dart';
import 'package:khoirunnasyien/features/app_config/domain/feature_access_policy.dart';
import 'package:khoirunnasyien/features/app_config/presentation/widgets/feature_unavailable_page.dart';

void main() {
  group('RuntimeAppConfig', () {
    test('fitur baru memakai default saat dokumen belum memiliki nilainya', () {
      final config = RuntimeAppConfig.fromMap(null);

      expect(config.isEnabled(AppFeature.tahfizArena), isTrue);
    });

    test('membaca dan menulis feature map dengan key yang stabil', () {
      final config = RuntimeAppConfig.fromMap({
        'features': {'tahfiz_arena': false},
      });

      expect(config.isEnabled(AppFeature.tahfizArena), isFalse);
      expect(config.toMap(), {
        'features': {'tahfiz_arena': false},
      });
    });
  });

  group('Tahfiz Arena access policy', () {
    final disabledConfig = RuntimeAppConfig.defaults().withFeature(
      AppFeature.tahfizArena,
      false,
    );

    test('admin tetap dapat mengakses', () {
      expect(
        resolveAppFeatureAccess(
          config: disabledConfig,
          feature: AppFeature.tahfizArena,
          role: UserRole.admin,
        ),
        AppFeatureAccess.enabled,
      );
    });

    test('menu asatidz disembunyikan', () {
      expect(
        resolveAppFeatureAccess(
          config: disabledConfig,
          feature: AppFeature.tahfizArena,
          role: UserRole.asatidz,
        ),
        AppFeatureAccess.hidden,
      );
    });

    test('santri mendapat halaman belum tersedia', () {
      expect(
        resolveAppFeatureAccess(
          config: disabledConfig,
          feature: AppFeature.tahfizArena,
          role: UserRole.santri,
        ),
        AppFeatureAccess.unavailable,
      );
    });
  });

  testWidgets('halaman santri menjelaskan fitur sedang dalam perbaikan', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeatureUnavailablePage(featureName: 'Tahfiz Arena'),
      ),
    );

    expect(find.text('Fitur Belum Tersedia'), findsOneWidget);
    expect(
      find.text(
        'Tahfiz Arena sedang dalam perbaikan. Silakan coba lagi nanti.',
      ),
      findsOneWidget,
    );
  });
}
