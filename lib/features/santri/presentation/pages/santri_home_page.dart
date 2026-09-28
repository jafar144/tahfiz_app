import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/whatsapp_utils.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/family/presentation/widgets/family_account_switcher.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_cubit.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';
import 'package:shimmer/shimmer.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_target_carousel.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';
import 'package:khoirunnasyien/features/journey/presentation/widgets/journey_summary_card.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/kelulusan_carousel.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_eligibility.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_santri_preview.dart';
import 'package:khoirunnasyien/core/services/app_update_service.dart';

class SantriHomePage extends StatefulWidget {
  const SantriHomePage({super.key});

  @override
  State<SantriHomePage> createState() => _SantriHomePageState();
}

class _SantriHomePageState extends State<SantriHomePage> {
  bool _isLoadingPembimbingContact = false;

  @override
  void initState() {
    super.initState();
    AppUpdateService.checkForFlexibleUpdate(context);
  }

  void _loadData() {
    final cubit = context.read<SantriHomeCubit>();
    final santriId = cubit.currentSantriId;
    if (santriId != null) {
      cubit.loadData(santriId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<SantriHomeCubit, SantriHomeState>(
          builder: (context, state) {
            if (state.status == SantriHomeStatus.loading ||
                state.status == SantriHomeStatus.initial) {
              return _buildLoading();
            }

            if (state.status == SantriHomeStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data:\n${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(state),
                    _buildJourneySection(state),
                    const KelulusanCarousel(),
                    _buildPaymentStatus(state),
                    if (state.latestReport != null) _buildLatestReport(state),
                    _buildSundayFajrPreview(state),
                    if (state.pembimbingName != null)
                      _buildPembimbingSection(state),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSundayFajrPreview(SantriHomeState state) {
    final authState = context.read<AuthCubit>().state;
    final santri = state.santri;
    if (authState is! AuthAuthenticated || santri == null) {
      return const SizedBox.shrink();
    }

    final authenticatedId = authState.user.uid;
    final selectedId = context.read<SantriHomeCubit>().currentSantriId;
    if (selectedId != authenticatedId) {
      // Riwayat attendance dibatasi rules untuk pemilik akun. Saat sedang
      // melihat anggota keluarga lain, jangan tampilkan data akun utama.
      return const SizedBox.shrink();
    }

    return SundayFajrSantriPreview(
      repository: getIt<SundayFajrAttendanceRepository>(),
      santriId: authenticatedId,
      isEligible: isSundayFajrEligible(
        isActive: santri.isActive,
        gender: santri.jenisKelamin,
        kelas: santri.kelas,
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 120, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 24, width: 200, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SantriHomeState state) {
    final santri = state.santri;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assalamua\'laikum', style: AppTextStyles.infoGrey),
              const SizedBox(height: 2),
              Text(
                santri?.name ?? 'Santri',
                style: AppTextStyles.mediumContentBlack,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (state.familyMembers.isNotEmpty ||
            state.familyMembersLoadFailed ||
            state.isLoadingFamilyMembers) ...[
          const SizedBox(width: 12),
          FamilyAccountSwitcher(
            accounts: state.familyMembers,
            onSwitch: context.read<AuthCubit>().switchSantri,
            loadFailed: state.familyMembersLoadFailed,
            isLoading: state.isLoadingFamilyMembers,
            onRetry: context.read<SantriHomeCubit>().retryFamilyAccounts,
          ),
        ],
        const SizedBox(width: 12),
        _buildAvatar(santri),
      ],
    );
  }

  Widget _buildAvatar(SantriDetail? santri) {
    final primary = Theme.of(context).primaryColor;
    return CircleAvatar(
      radius: 22,
      backgroundColor: primary.withValues(alpha: 0.1),
      backgroundImage:
          (santri?.photoUrl != null && santri!.photoUrl!.isNotEmpty)
          ? NetworkImage(santri.photoUrl!)
          : null,
      child: (santri?.photoUrl == null || santri!.photoUrl!.isEmpty)
          ? Text(
              _getInitials(santri?.name ?? 'S'),
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  Widget _buildJourneySection(SantriHomeState state) {
    final kelas = state.santri?.kelas;
    final info = JourneyBuilder.build(kelas);
    if (!info.hasCurrent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: JourneySummaryCard(
        info: info,
        onTap: () => context.pushNamed(RouteNames.journey, extra: kelas),
      ),
    );
  }

  Widget _buildPaymentStatus(SantriHomeState state) {
    final primary = Theme.of(context).primaryColor;
    final isFree = state.santri?.isFree ?? false;
    final isPaidAll = state.overdueMonthsCount == 0;

    final Color accent;
    final Color accentDark;
    final IconData statusIcon;
    final String statusTitle;
    final String statusSubtitle;

    if (isFree) {
      accent = primary;
      accentDark = const Color(0xFF1565C0);
      statusIcon = Icons.volunteer_activism_rounded;
      statusTitle = 'Bebas SPP';
      statusSubtitle = 'Santri ini gratis, tidak ada tagihan SPP';
    } else if (isPaidAll) {
      accent = const Color(0xFF16A34A);
      accentDark = const Color(0xFF15803D);
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Lunas Bulan Ini';
      statusSubtitle = 'Pembayaran SPP kamu aman';
    } else {
      accent = const Color(0xFFEF4444);
      accentDark = const Color(0xFFB91C1C);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = '${state.overdueMonthsCount} Bulan Menunggak';
      statusSubtitle = 'Yuk segera selesaikan pembayaran';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi SPP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accentDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusSubtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isFree) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      final startDate = state.santri != null
                          ? PaymentUtils.resolveStartDate(
                              freeUntil: state.santri!.freeUntil,
                              tanggalMasuk: state.santri!.tanggalMasuk,
                            )
                          : null;
                      final currentSantriId = context
                          .read<SantriHomeCubit>()
                          .currentSantriId;
                      context.pushNamed(
                        RouteNames.santriPayment,
                        extra: {
                          'startDate': startDate,
                          'santriId': currentSantriId,
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lihat Data Pembayaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestReport(SantriHomeState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthlyTargetCarousel(reports: state.monthlyReports),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Penilaian Terakhir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final santriId = context
                      .read<SantriHomeCubit>()
                      .currentSantriId;
                  if (santriId == null) return;
                  context.pushNamed(RouteNames.santriReports, extra: santriId);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 17),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MonthlyReportCard(
            report: state.latestReport!,
            periodTarget: MonthlyTargetProgress.forAssessment(
              state.latestReport!,
              state.monthlyReports,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPembimbingSection(SantriHomeState state) {
    final primary = Theme.of(context).primaryColor;
    final phone = state.pembimbingPhone;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengajar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primary.withValues(alpha: 0.1),
                      child: Text(
                        _getInitials(state.pembimbingName!),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.pembimbingDisplayName!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                phone != null
                                    ? Icons.phone_outlined
                                    : Icons.school_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  phone ?? 'Pembimbing halaqah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingPembimbingContact
                        ? null
                        : () => _contactPembimbing(phone),
                    icon: _isLoadingPembimbingContact
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.chat_bubble_rounded, size: 14),
                    label: Text(
                      _isLoadingPembimbingContact
                          ? 'Memuat nomor...'
                          : 'Hubungi via WhatsApp',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      disabledBackgroundColor: const Color(0xFF25D366),
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactPembimbing(String? loadedPhone) async {
    var phone = loadedPhone;
    if (phone == null) {
      setState(() => _isLoadingPembimbingContact = true);
      phone = await context.read<SantriHomeCubit>().retryPembimbingContact();
      if (!mounted) return;
      setState(() => _isLoadingPembimbingContact = false);
    }

    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nomor WhatsApp pembimbing belum dapat dimuat. Coba lagi.',
          ),
        ),
      );
      return;
    }

    await _launchWhatsApp(phone);
  }

  Future<void> _launchWhatsApp(String rawPhone) async {
    final result = await WhatsAppUtils.launch(rawPhone);
    if (!mounted || result == WhatsAppLaunchResult.opened) return;

    final message = switch (result) {
      WhatsAppLaunchResult.invalidPhone =>
        'Nomor WhatsApp pembimbing tidak valid. Hubungi admin untuk memperbarui nomor.',
      WhatsAppLaunchResult.unavailable =>
        'WhatsApp tidak dapat dibuka. Pastikan WhatsApp atau browser tersedia.',
      WhatsAppLaunchResult.opened => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
