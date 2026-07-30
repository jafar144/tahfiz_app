import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_cubit.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_state.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_widgets.dart';

class SundayFajrSantriHistoryPage extends StatelessWidget {
  const SundayFajrSantriHistoryPage({
    super.key,
    required this.repository,
    required this.santriId,
  });

  final SundayFajrAttendanceRepository repository;
  final String santriId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SundayFajrSantriCubit(repository: repository, santriId: santriId)
            ..load(),
      child: const _SundayFajrSantriHistoryView(),
    );
  }
}

class _SundayFajrSantriHistoryView extends StatelessWidget {
  const _SundayFajrSantriHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AiwaAppBar(title: 'Riwayat Minggu Subuh'),
      body: BlocBuilder<SundayFajrSantriCubit, SundayFajrSantriState>(
        builder: (context, state) {
          return switch (state.status) {
            SundayFajrSantriStatus.initial || SundayFajrSantriStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            SundayFajrSantriStatus.failure => _HistoryError(
              message: state.errorMessage ?? 'Riwayat tidak dapat dimuat.',
              onRetry: context.read<SundayFajrSantriCubit>().load,
            ),
            SundayFajrSantriStatus.loaded when state.history.isEmpty =>
              const _HistoryEmpty(),
            SundayFajrSantriStatus.loaded => RefreshIndicator(
              onRefresh: context.read<SundayFajrSantriCubit>().load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _SantriHistoryCard(participant: state.history[index]),
              ),
            ),
          };
        },
      ),
    );
  }
}

class _SantriHistoryCard extends StatelessWidget {
  const _SantriHistoryCard({required this.participant});

  final SundayFajrParticipant participant;

  @override
  Widget build(BuildContext context) {
    final style = SundayFajrStatusStyle.of(participant.status);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatSundayFajrDate(participant.eventDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SundayFajrStatusBadge(
                      status: participant.status,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 60, color: Color(0xFFCBD5E1)),
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
              'Kehadiran Minggu Subuh kamu akan tampil setelah dicatat admin.',
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

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

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
              size: 52,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
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
