import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_cubit.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_state.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';

class AppConfigPage extends StatelessWidget {
  const AppConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final canManage =
        authState is AuthAuthenticated &&
        (authState.user.role == UserRole.admin || authState.user.isAdmin);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const AiwaAppBar(title: 'App Config'),
      body: canManage
          ? BlocConsumer<AppConfigCubit, AppConfigState>(
              listenWhen: (previous, current) =>
                  current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage,
              listener: (context, state) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              },
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Fitur Aplikasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aktifkan atau nonaktifkan fitur tanpa memperbarui aplikasi.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FeatureConfigTile(
                      feature: AppFeature.tahfizArena,
                      enabled: state.config.isEnabled(AppFeature.tahfizArena),
                      updating:
                          state.status == AppConfigStatus.initial ||
                          state.status == AppConfigStatus.loading ||
                          state.isUpdating(AppFeature.tahfizArena),
                      onChanged: (enabled) =>
                          _updateTahfizArena(context, enabled),
                    ),
                  ],
                );
              },
            )
          : const _AccessDenied(),
    );
  }

  Future<void> _updateTahfizArena(BuildContext context, bool enabled) async {
    if (!enabled) {
      final confirmed = await showAiwaActionSheet<bool>(
        context: context,
        title: 'Nonaktifkan Tahfiz Arena?',
        content: const Text(
          'Menu asatidz akan disembunyikan dan santri akan melihat '
          'pemberitahuan bahwa fitur sedang dalam perbaikan.',
        ),
        confirmText: 'Nonaktifkan',
        confirmValue: true,
        cancelValue: false,
        confirmColor: Colors.red,
      );
      if (confirmed != true || !context.mounted) return;
    }

    await context.read<AppConfigCubit>().setFeatureEnabled(
      AppFeature.tahfizArena,
      enabled,
    );
  }
}

class _FeatureConfigTile extends StatelessWidget {
  final AppFeature feature;
  final bool enabled;
  final bool updating;
  final ValueChanged<bool> onChanged;

  const _FeatureConfigTile({
    required this.feature,
    required this.enabled,
    required this.updating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: updating ? null : onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: updating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.teal,
                ),
              ),
        title: Text(
          feature.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          enabled
              ? 'Tersedia untuk seluruh pengguna.'
              : 'Santri melihat pemberitahuan; menu asatidz disembunyikan.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.35),
        ),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Hanya admin yang dapat mengubah App Config.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
