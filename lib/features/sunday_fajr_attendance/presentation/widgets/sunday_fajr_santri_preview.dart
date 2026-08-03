import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_cubit.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_state.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_monthly_calendar.dart';

/// Loader + access gate untuk kalender Minggu Subuh milik satu santri.
///
/// [isEligible] sengaja diperiksa sebelum query agar akun yang tidak termasuk
/// roster (nonaktif, putri, atau kelas Tahsin) tidak membuka data yang tidak
/// relevan.
class SundayFajrSantriPreview extends StatelessWidget {
  const SundayFajrSantriPreview({
    super.key,
    required this.repository,
    required this.santriId,
    required this.isEligible,
    this.now,
    this.topSpacing = 28,
  });

  final SundayFajrAttendanceRepository repository;
  final String santriId;
  final bool isEligible;
  final DateTime? now;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final visibleMonths = SundayFajrCalendarPeriod.visibleMonths(
      now ?? DateTime.now(),
    );
    if (!isEligible || visibleMonths.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => SundayFajrSantriCubit(
        repository: repository,
        santriId: santriId,
        limit: 24,
      )..load(),
      child: Padding(
        padding: EdgeInsets.only(top: topSpacing),
        child: _SundayFajrSantriCalendarView(now: now),
      ),
    );
  }
}

class _SundayFajrSantriCalendarView extends StatelessWidget {
  const _SundayFajrSantriCalendarView({required this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SundayFajrSantriCubit, SundayFajrSantriState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (state.status) {
            SundayFajrSantriStatus.initial ||
            SundayFajrSantriStatus.loading => const _CalendarLoading(),
            SundayFajrSantriStatus.failure => _CalendarError(
              message: state.errorMessage ?? 'Kehadiran tidak dapat dimuat.',
              onRetry: context.read<SundayFajrSantriCubit>().load,
            ),
            SundayFajrSantriStatus.loaded => SundayFajrMonthlyCalendar(
              history: state.history,
              now: now,
            ),
          },
        );
      },
    );
  }
}

class _CalendarLoading extends StatelessWidget {
  const _CalendarLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('sunday-fajr-calendar-loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LoadingBox(width: 160, height: 14),
        const SizedBox(height: 12),
        Container(
          height: 226,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ],
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _CalendarError extends StatelessWidget {
  const _CalendarError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sunday-fajr-calendar-error'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: Color(0xFFC2410C),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
