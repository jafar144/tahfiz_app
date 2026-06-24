import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_state.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_attendance_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/halaqah_deposit_list_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/select_santri_page.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/monthly_report_list_page.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/pages/syahadah_generator_page.dart';

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
  }

  @override
  Widget build(BuildContext context) {
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

          if (state is AsatidzDashboardError && state.message.contains('Error loading dashboard')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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
                    const Text('Menu', style: AppTextStyles.mediumContentBlack),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MonthlyReportListPage(),
                              ),
                            );
                          },
                        ),
                        MenuCard(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Kelulusan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SyahadahGeneratorPage(),
                              ),
                            );
                          },
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
                      Container(width: 80, height: 12, color: Colors.grey.shade200),
                      const SizedBox(height: 6),
                      Container(width: 40, height: 20, color: Colors.grey.shade300),
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
                        width: 36, height: 36,
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
                            Container(width: 100, height: 12, color: Colors.grey.shade200),
                            const SizedBox(height: 4),
                            Container(width: 140, height: 12, color: Colors.grey.shade200),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Container(width: 180, height: 18, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Container(width: 200, height: 14, color: Colors.grey.shade200),
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
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(width: 60, height: 14, color: Colors.grey.shade200),
                        const SizedBox(height: 4),
                        Container(width: 80, height: 12, color: Colors.grey.shade200),
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
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(width: 60, height: 14, color: Colors.grey.shade200),
                        const SizedBox(height: 4),
                        Container(width: 80, height: 12, color: Colors.grey.shade200),
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
        final userName = state is AuthAuthenticated ? state.user.name : 'Asatidz';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assalamu\'alaikum',
              style: AppTextStyles.infoGrey,
            ),
            const SizedBox(height: 2),
            Text(
              userName,
              style: AppTextStyles.mediumContentBlack,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, AsatidzDashboardLoaded state) {
    final activeHalaqah = state.activeHalaqah!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.school, color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESI MENGAJAR',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sesi Aktif Sekarang',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.class_, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Nama Halaqah',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            activeHalaqah.halaqah.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${activeHalaqah.schedule.startTime} - ${activeHalaqah.schedule.endTime}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${activeHalaqah.halaqah.santriCount} Santri',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAttendanceButton(context, activeHalaqah, state),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(BuildContext context, ActiveHalaqah activeHalaqah, AsatidzDashboardLoaded state) {
    if (state.hasAttendedToday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sudah Absen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'Terima kasih sudah hadir hari ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AiwaButton(
      text: 'Absen Sekarang',
      isLoading: state.isCheckingIn,
      onPressed: () {
        context.read<AsatidzDashboardCubit>().checkInAsatidz(activeHalaqah);
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, AsatidzDashboardLoaded state) {
    if (state.activeHalaqah == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: Colors.teal.shade400,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak Ada Halaqah Aktif',
              style: AppTextStyles.smallContentBlack,
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada sesi halaqah yang berjalan saat ini',
              style: AppTextStyles.infoLightGrey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final canAccess = state.hasAttendedToday;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.how_to_reg_rounded,
                title: 'Absensi',
                subtitle: 'Kehadiran Santri',
                enabled: canAccess,
                onTap: () {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthAuthenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) => SantriAttendanceCubit(
                            repository: getIt(),
                            scheduleRepository: getIt(),
                            activeHalaqah: state.activeHalaqah!,
                            asatidzId: authState.user.uid,
                            asatidzName: authState.user.name,
                          )..init(),
                          child: SantriAttendancePage(
                            activeHalaqah: state.activeHalaqah!,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Input Setoran',
                subtitle: 'Setoran Santri',
                enabled: canAccess,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AsatidzDashboardCubit>(),
                        child: HalaqahDepositListPage(
                          activeHalaqah: state.activeHalaqah!,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_add_rounded,
                title: 'Santri Tambahan',
                subtitle: 'Tambah Sementara',
                enabled: canAccess,
                onTap: () async {
                  final cubit = context.read<AsatidzDashboardCubit>();
                  final params = await cubit.getGuestSantriParams(state.activeHalaqah!);
                  
                  if (params == null || !context.mounted) return;

                  final gender = params['gender'] as String?;
                  final disabledIds = params['disabledIds'] as List<String>;
                  final meetingId = params['meetingId'] as String;

                  final selectedSantri = await Navigator.push<SantriEntity>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (_) => SantriCubit(getIt())..loadSantri(
                          isActive: true,
                          gender: gender,
                          isFree: false,
                        ),
                        child: SelectSantriPage(
                          genderFiltered: gender,
                          disabledIds: disabledIds,
                          isMultiSelect: false,
                        ),
                      ),
                    ),
                  );

                  if (selectedSantri != null && context.mounted) {
                     cubit.addGuestSantri(meetingId, selectedSantri);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: const SizedBox()),
          ],
        ),
        if (!canAccess) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Silakan absen terlebih dahulu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final cardColor = enabled ? theme.primaryColor : Colors.grey;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cardColor.withValues(alpha: 0.1),
                child: Icon(icon, color: cardColor, size: 24),
              ),
              const SizedBox(height: 14),
              Text(title, style: AppTextStyles.smallContentBlack),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: AppTextStyles.infoLightGrey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

