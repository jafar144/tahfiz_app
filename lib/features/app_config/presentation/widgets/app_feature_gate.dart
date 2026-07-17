import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/feature_access_policy.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_cubit.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_state.dart';
import 'package:khoirunnasyien/features/app_config/presentation/widgets/feature_unavailable_page.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';

class AppFeatureGate extends StatelessWidget {
  final AppFeature feature;
  final Widget child;

  const AppFeatureGate({super.key, required this.feature, required this.child});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final configState = context.watch<AppConfigCubit>().state;

    if (configState.status == AppConfigStatus.initial ||
        configState.status == AppConfigStatus.loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState is! AuthAuthenticated) {
      return FeatureUnavailablePage(featureName: feature.label);
    }

    final access = resolveAppFeatureAccess(
      config: configState.config,
      feature: feature,
      role: authState.user.role,
    );

    if (access == AppFeatureAccess.enabled) return child;
    return FeatureUnavailablePage(featureName: feature.label);
  }
}
