import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_admin_cubit.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_admin_state.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/pages/sunday_fajr_editor_page.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SundayFajrAdminPage extends StatelessWidget {
  const SundayFajrAdminPage({
    super.key,
    required this.repository,
    required this.adminId,
    this.now,
  });

  final SundayFajrAttendanceRepository repository;
  final String adminId;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SundayFajrAdminCubit(repository)..load(),
      child: _SundayFajrAdminView(
        repository: repository,
        adminId: adminId,
        now: now,
      ),
    );
  }
}

class _SundayFajrAdminView extends StatelessWidget {
  const _SundayFajrAdminView({
    required this.repository,
    required this.adminId,
    this.now,
  });

  final SundayFajrAttendanceRepository repository;
  final String adminId;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SundayFajrAdminCubit, SundayFajrAdminState>(
      builder: (context, state) {
        final effectiveNow = now ?? DateTime.now();
        final currentSunday = SundayFajrAttendancePolicy.latestSunday(
          now: effectiveNow,
        );
        final currentWeekKey = SundayFajrAttendancePolicy.weekKey(
          currentSunday,
        );
        final currentRecordExists = state.history.any(
          (attendance) => attendance.weekKey == currentWeekKey,
        );
        final canCreate = SundayFajrAttendancePolicy.canCreate(
          currentSunday,
          now: effectiveNow,
        );
        final isLoading =
            state.status == SundayFajrAdminStatus.initial ||
            state.status == SundayFajrAdminStatus.loading;
        final showAddButton =
            !isLoading &&
            state.status != SundayFajrAdminStatus.failure &&
            canCreate &&
            !currentRecordExists;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: const AiwaAppBar(title: 'Minggu Subuh'),
          floatingActionButton: showAddButton
              ? FloatingActionButton.extended(
                  key: const Key('add-sunday-fajr-attendance'),
                  onPressed: () => _openEditor(context, currentSunday),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Tambah Absensi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
          body:
              state.status == SundayFajrAdminStatus.failure &&
                  state.history.isEmpty
              ? _ErrorView(
                  message: state.errorMessage ?? 'Data tidak dapat dimuat.',
                  onRetry: context.read<SundayFajrAdminCubit>().load,
                )
              : RefreshIndicator(
                  onRefresh: context.read<SundayFajrAdminCubit>().load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _RecordsHeader(
                            totalRecords: state.history.length,
                            canCreate: canCreate,
                            currentRecordExists: currentRecordExists,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Catatan Absensi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (state.history.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${state.history.length} minggu',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (isLoading)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverList.separated(
                            itemCount: 4,
                            itemBuilder: (_, _) =>
                                const _AttendanceCardSkeleton(),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                          ),
                        )
                      else if (state.history.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyHistory(canCreate: canCreate),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                          sliver: SliverList.separated(
                            itemCount: state.history.length,
                            itemBuilder: (context, index) {
                              final attendance = state.history[index];
                              return _AttendanceHistoryCard(
                                attendance: attendance,
                                now: effectiveNow,
                                onTap: () =>
                                    _openEditor(context, attendance.eventDate),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context, DateTime eventDate) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SundayFajrEditorPage(
          repository: repository,
          actorId: adminId,
          eventDate: eventDate,
          now: now,
        ),
      ),
    );
    if (changed == true && context.mounted) {
      await context.read<SundayFajrAdminCubit>().load();
    }
  }
}

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader({
    required this.totalRecords,
    required this.canCreate,
    required this.currentRecordExists,
  });

  final int totalRecords;
  final bool canCreate;
  final bool currentRecordExists;

  @override
  Widget build(BuildContext context) {
    final message = canCreate
        ? currentRecordExists
              ? 'Absensi minggu ini sudah tersimpan. Buka catatannya untuk melakukan perubahan.'
              : 'Hari ini jadwal pencatatan. Gunakan tombol Tambah Absensi untuk memulai.'
        : 'Absensi baru dapat dibuat setiap hari Minggu. Catatan lama tetap dapat dilihat kapan saja.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF4FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E9FB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Rekap Minggu Subuh',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$totalRecords data',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  const _AttendanceHistoryCard({
    required this.attendance,
    required this.now,
    required this.onTap,
  });

  final SundayFajrAttendance attendance;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final editable = SundayFajrAttendancePolicy.isEditable(
      attendance.eventDate,
      now: now,
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatSundayFajrDate(
                            attendance.eventDate,
                            pattern: 'dd',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatSundayFajrDate(
                            attendance.eventDate,
                            pattern: 'MMM',
                          ).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatSundayFajrDate(
                            attendance.eventDate,
                            pattern: 'EEEE, d MMMM yyyy',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${attendance.participantCount} santri • Revisi ${attendance.revision}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: editable
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          editable
                              ? Icons.edit_rounded
                              : Icons.lock_outline_rounded,
                          size: 11,
                          color: editable
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          editable ? 'Edit' : 'Selesai',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: editable
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 21,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SundayFajrDistributionBar(
                hadir: attendance.totalHadir,
                izin: attendance.totalIzin,
                alpha: attendance.totalAlpha,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CompactMetric(
                      label: 'Hadir',
                      value: attendance.totalHadir,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                  Expanded(
                    child: _CompactMetric(
                      label: 'Izin',
                      value: attendance.totalIzin,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  Expanded(
                    child: _CompactMetric(
                      label: 'Alpha',
                      value: attendance.totalAlpha,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $value',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AttendanceCardSkeleton extends StatelessWidget {
  const _AttendanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minggu, 20 Juli 2026'),
            SizedBox(height: 18),
            Text('75 santri tercatat pada absensi ini'),
            Spacer(),
            SundayFajrSummaryRow(hadir: 70, izin: 3, alpha: 2),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 104),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 34,
                color: Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada catatan absensi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              canCreate
                  ? 'Tekan Tambah Absensi untuk mencatat kehadiran Minggu Subuh hari ini.'
                  : 'Catatan pertama dapat dibuat pada hari Minggu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
