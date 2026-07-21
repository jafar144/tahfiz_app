import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_state.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/core/services/app_update_service.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/feature_access_policy.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_cubit.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_state.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';

class AsatidzDashboardPage extends StatefulWidget {
  const AsatidzDashboardPage({super.key});

  @override
  State<AsatidzDashboardPage> createState() => _AsatidzDashboardPageState();
}

class _AsatidzDashboardPageState extends State<AsatidzDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AsatidzDashboardCubit>().loadDashboard();
    AppUpdateService.checkForFlexibleUpdate(context);
  }

  @override
  Widget build(BuildContext context) {
    final appConfigState = context.watch<AppConfigCubit>().state;
    final configReady =
        appConfigState.status != AppConfigStatus.initial &&
        appConfigState.status != AppConfigStatus.loading;
    final showTahfizArena =
        configReady &&
        resolveAppFeatureAccess(
              config: appConfigState.config,
              feature: AppFeature.tahfizArena,
              role: UserRole.asatidz,
            ) ==
            AppFeatureAccess.enabled;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: BlocConsumer<AsatidzDashboardCubit, AsatidzDashboardState>(
          listener: (context, state) {
            if (state is AsatidzDashboardSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Refresh to load the newly added santri
              context.read<AsatidzDashboardCubit>().loadDashboard();
            } else if (state is AsatidzDashboardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AsatidzDashboardLoading) {
              return _buildSkeletonDashboard();
            }

            if (state is AsatidzDashboardError &&
                state.message.contains('Error loading dashboard')) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                  ],
                ),
              );
            }

            if (state is AsatidzDashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<AsatidzDashboardCubit>().loadDashboard();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingHeader(context),
                      const SizedBox(height: 16),
                      InfoCard(
                        title: 'Total Santri',
                        value: '${state.totalSantri}',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Menu',
                        style: AppTextStyles.mediumContentBlack,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          MenuCard(
                            icon: Icons.assessment_rounded,
                            title: 'Penilaian',
                            onTap: () =>
                                context.pushNamed(RouteNames.monthlyReport),
                          ),
                          MenuCard(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Kelulusan',
                            onTap: () =>
                                context.pushNamed(RouteNames.adminSyahadah),
                          ),
                          if (showTahfizArena)
                            MenuCard(
                              icon: Icons.sports_esports_rounded,
                              title: 'Tahfiz Arena',
                              onTap: () => context.pushNamed(RouteNames.arena),
                            ),
                        ],
                      ),
                      // if (state.activeHalaqah != null) ...[
                      //   _buildActiveSessionCard(context, state),
                      //   const SizedBox(height: 20),
                      // ],
                      // _buildQuickActions(context, state),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonDashboard() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 14, color: Colors.grey.shade300),
                const SizedBox(height: 6),
                Container(width: 100, height: 18, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.grey.shade200,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 140,
                              height: 12,
                              color: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Container(
                    width: 180,
                    height: 18,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 200,
                    height: 14,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 60,
                          height: 14,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 60,
                          height: 14,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state is AuthAuthenticated
            ? state.user.name
            : 'Asatidz';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assalamu\'alaikum', style: AppTextStyles.infoGrey),
            const SizedBox(height: 2),
            Text(userName, style: AppTextStyles.mediumContentBlack),
          ],
        );
      },
    );
  }
}
