import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_cubit.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_state.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/pages/sunday_fajr_santri_history_page.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_widgets.dart';

class SundayFajrSantriPreview extends StatelessWidget {
  const SundayFajrSantriPreview({
    super.key,
    required this.repository,
    required this.santriId,
    required this.isEligible,
    this.onOpenHistory,
  });

  final SundayFajrAttendanceRepository repository;
  final String santriId;
  final bool isEligible;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SundayFajrSantriCubit(
        repository: repository,
        santriId: santriId,
        limit: 1,
      )..load(),
      child: BlocBuilder<SundayFajrSantriCubit, SundayFajrSantriState>(
        builder: (context, state) {
          // Santri yang tidak lagi memenuhi kriteria tetap dapat membuka
          // catatan lamanya. Bila memang belum pernah punya catatan, bagian
          // ini tetap disembunyikan agar Beranda tidak menampilkan fitur yang
          // tidak relevan baginya.
          if (!isEligible &&
              (state.status != SundayFajrSantriStatus.loaded ||
                  state.latest == null)) {
            return const SizedBox.shrink();
          }
          return _SundayFajrSantriPreviewView(
            repository: repository,
            santriId: santriId,
            onOpenHistory: onOpenHistory,
          );
        },
      ),
    );
  }
}

class _SundayFajrSantriPreviewView extends StatelessWidget {
  const _SundayFajrSantriPreviewView({
    required this.repository,
    required this.santriId,
    this.onOpenHistory,
  });

  final SundayFajrAttendanceRepository repository;
  final String santriId;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kehadiran Minggu Subuh',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<SundayFajrSantriCubit, SundayFajrSantriState>(
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (state.status) {
                  SundayFajrSantriStatus.initial ||
                  SundayFajrSantriStatus.loading => const _PreviewLoading(),
                  SundayFajrSantriStatus.failure => _PreviewError(
                    message:
                        state.errorMessage ?? 'Riwayat tidak dapat dimuat.',
                    onRetry: context.read<SundayFajrSantriCubit>().load,
                  ),
                  SundayFajrSantriStatus.loaded when state.latest == null =>
                    _PreviewEmpty(onTap: () => _openHistory(context)),
                  _ => _PreviewData(
                    participant: state.latest!,
                    onTap: () => _openHistory(context),
                  ),
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context) {
    if (onOpenHistory != null) {
      onOpenHistory!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SundayFajrSantriHistoryPage(
          repository: repository,
          santriId: santriId,
        ),
      ),
    );
  }
}

class _PreviewData extends StatelessWidget {
  const _PreviewData({required this.participant, required this.onTap});

  final SundayFajrParticipant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('sunday-fajr-preview-data'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.wb_twilight_rounded,
                      color: AppColors.primary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatSundayFajrDate(
                            participant.eventDate,
                            pattern: 'd MMMM yyyy',
                          ),
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
              if (participant.izinReason.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    'Alasan: ${participant.izinReason}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lihat seluruh riwayat',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
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

class _PreviewEmpty extends StatelessWidget {
  const _PreviewEmpty({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('sunday-fajr-preview-empty'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.event_note_outlined,
                color: Color(0xFF94A3B8),
                size: 26,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum ada catatan kehadiran',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Riwayat akan tampil setelah admin menyimpan absensi.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sunday-fajr-preview-loading'),
      height: 94,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(17),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sunday-fajr-preview-error'),
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
