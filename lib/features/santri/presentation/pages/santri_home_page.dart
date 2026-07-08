
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_cubit.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';
import 'package:khoirunnasyien/features/santri/presentation/widgets/santri_setoran_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';
import 'package:khoirunnasyien/features/journey/presentation/widgets/journey_summary_card.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/kelulusan_carousel.dart';
import 'package:khoirunnasyien/core/services/app_update_service.dart';

class SantriHomePage extends StatefulWidget {
  const SantriHomePage({super.key});

  @override
  State<SantriHomePage> createState() => _SantriHomePageState();
}

class _SantriHomePageState extends State<SantriHomePage> {
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
          if (state.status == SantriHomeStatus.loading || state.status == SantriHomeStatus.initial) {
            return _buildLoading();
          }

          if (state.status == SantriHomeStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data:\n${state.message}', textAlign: TextAlign.center),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  _buildJourneySection(state),
                  // _buildArenaCard(),
                  const KelulusanCarousel(),
                  _buildPaymentStatus(state),
                  // _buildMenuSection(context),
                  // if (state.latestSetoran != null) _buildLatestSetoran(state),
                  if (state.latestReport != null) _buildLatestReport(state),
                  if (state.pembimbingName != null) _buildPembimbingSection(state),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    ));
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
    final hasFamily = state.familyMembers.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assalamua\'laikum',
                style: AppTextStyles.infoGrey,
              ),
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
        if (hasFamily) ...[
          const SizedBox(width: 12),
          _buildSwitchAccountButton(),
        ],
        const SizedBox(width: 12),
        _buildAvatar(santri),
      ],
    );
  }

  Widget _buildSwitchAccountButton() {
    final primary = Theme.of(context).primaryColor;
    return Material(
      color: primary.withOpacity(0.1),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _showSwitchAccountSheet,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.swap_horiz_rounded,
            color: primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(SantriDetail? santri) {
    final primary = Theme.of(context).primaryColor;
    return CircleAvatar(
      radius: 22,
      backgroundColor: primary.withOpacity(0.1),
      backgroundImage: (santri?.photoUrl != null && santri!.photoUrl!.isNotEmpty)
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

  void _showSwitchAccountSheet() {
    final members = context.read<SantriHomeCubit>().state.familyMembers;
    if (members.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Ganti Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...members.map((member) {
                final isMale = member.jenisKelamin == 'L';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMale ? Colors.blue.shade700 : Colors.pink.shade700,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'NIS: ${member.nis} • ${member.kelas}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<AuthCubit>().switchSantri(member.id);
                  },
                );
              }),
            ],
          ),
        ),
      ),
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

  /// Kartu pintu masuk Tahfiz Arena (Petualangan Surah + Kuis + Papan Juara)
  /// bernuansa malam, senada dengan gaya Arena.
  Widget _buildArenaCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(RouteNames.arena),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2540), Color(0xFF123B33)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B2540).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Color(0xFFF6A609),
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tahfiz Arena',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Petualangan surah, kuis hafalan, dan papan juara '
                        'kelasmu — main sambil muroja\'ah!',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
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
                      child: Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 22,
                      ),
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
                          ? PaymentUtils.resolveStartDate(state.santri!)
                          : null;
                      final currentSantriId =
                          context.read<SantriHomeCubit>().currentSantriId;
                      context.pushNamed(RouteNames.santriPayment, extra: {
                        'startDate': startDate,
                        'santriId': currentSantriId,
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 16, color: primary),
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
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: primary),
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

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu Utama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMenuCard(
                  title: 'Setoran',
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMenuCard(
                  title: 'Presensi',
                  icon: Icons.fact_check_rounded,
                  color: Colors.orange,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMenuCard(
                  title: 'Jadwal',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.purple,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSetoran(SantriHomeState state) {
    final setoran = state.latestSetoran!;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Setoran Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SantriSetoranCard(setoran: setoran),
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
          const Text(
            'Penilaian Terakhir',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          MonthlyReportCard(report: state.latestReport!),
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
                if (phone != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchWhatsApp(phone),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                      label: const Text(
                        'Hubungi via WhatsApp',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(String rawPhone) async {
    var phone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return;
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }

    final url = Uri.parse('https://wa.me/$phone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
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
