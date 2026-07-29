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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AiwaAppBar(title: 'Minggu Subuh'),
      body: BlocBuilder<SundayFajrAdminCubit, SundayFajrAdminState>(
        builder: (context, state) {
          if (state.status == SundayFajrAdminStatus.failure &&
              state.history.isEmpty) {
            return _ErrorView(
              message: state.errorMessage ?? 'Data tidak dapat dimuat.',
              onRetry: context.read<SundayFajrAdminCubit>().load,
            );
          }

          final isLoading =
              state.status == SundayFajrAdminStatus.initial ||
              state.status == SundayFajrAdminStatus.loading;
          return RefreshIndicator(
            onRefresh: context.read<SundayFajrAdminCubit>().load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CreateAttendanceCard(
                      onTap: () => _showDateSelection(context, state.history),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Riwayat Mingguan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (state.history.isNotEmpty)
                          Text(
                            '${state.history.length} data',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: 4,
                      itemBuilder: (_, _) => const _AttendanceCardSkeleton(),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                    ),
                  )
                else if (state.history.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyHistory(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final attendance = state.history[index];
                        return _AttendanceHistoryCard(
                          attendance: attendance,
                          onTap: () =>
                              _openEditor(context, attendance.eventDate),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDateSelection(
    BuildContext context,
    List<SundayFajrAttendance> history,
  ) async {
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final dates = SundayFajrAttendancePolicy.editableSundays(now: now);
        final options = dates.map((date) {
          final exists = history.any(
            (item) => item.weekKey == SundayFajrAttendancePolicy.weekKey(date),
          );
          final canCreate = SundayFajrAttendancePolicy.canCreate(
            date,
            now: now,
          );
          return _DateOption(
            date: date,
            label: date == dates.first ? 'Minggu terbaru' : 'Minggu sebelumnya',
            exists: exists,
            canCreate: canCreate,
            onTap: exists || canCreate
                ? () => Navigator.pop(sheetContext, date)
                : null,
          );
        }).toList();
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Minggu',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Data baru hanya dapat dibuat pada hari Minggu. Data satu Minggu sebelumnya tetap dapat diedit jika sudah ada.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < options.length; index++) ...[
                  options[index],
                  if (index != options.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (selectedDate == null || !context.mounted) return;
    await _openEditor(context, selectedDate);
  }

  Future<void> _openEditor(BuildContext context, DateTime eventDate) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SundayFajrEditorPage(
          repository: repository,
          actorId: adminId,
          eventDate: eventDate,
        ),
      ),
    );
    if (changed == true && context.mounted) {
      await context.read<SundayFajrAdminCubit>().load();
    }
  }
}

class _CreateAttendanceCard extends StatelessWidget {
  const _CreateAttendanceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wb_twilight_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Absensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Catat hadir, izin, dan alpha untuk kegiatan Minggu Subuh.',
                      style: TextStyle(
                        color: Color(0xFFDDEEFF),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateOption extends StatelessWidget {
  const _DateOption({
    required this.date,
    required this.label,
    required this.exists,
    required this.canCreate,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool exists;
  final bool canCreate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Opacity(
      opacity: available ? 1 : 0.62,
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatSundayFajrDate(date),
                        style: const TextStyle(
                          fontSize: 11.5,
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
                    color: exists
                        ? const Color(0xFFDBEAFE)
                        : canCreate
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exists
                        ? 'Edit'
                        : canCreate
                        ? 'Buat'
                        : 'Belum tersedia',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: exists
                          ? const Color(0xFF1D4ED8)
                          : canCreate
                          ? const Color(0xFF15803D)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  const _AttendanceHistoryCard({required this.attendance, required this.onTap});

  final SundayFajrAttendance attendance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final editable = SundayFajrAttendancePolicy.isEditable(
      attendance.eventDate,
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatSundayFajrDate(
                            attendance.eventDate,
                            pattern: 'd MMMM yyyy',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${attendance.participantCount} santri - Revisi ${attendance.revision}',
                          style: const TextStyle(
                            fontSize: 11,
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
                    child: Text(
                      editable ? 'Dapat diedit' : 'Terkunci',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: editable
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              SundayFajrSummaryRow(
                hadir: attendance.totalHadir,
                izin: attendance.totalIzin,
                alpha: attendance.totalAlpha,
              ),
            ],
          ),
        ),
      ),
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
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minggu, 20 Juli 2026'),
            SizedBox(height: 12),
            Expanded(child: SundayFajrSummaryRow(hadir: 70, izin: 5, alpha: 2)),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 58,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 14),
            Text(
              'Belum ada riwayat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Data Minggu Subuh yang disimpan akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
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
