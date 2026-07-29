import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_editor_cubit.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_editor_state.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SundayFajrEditorPage extends StatelessWidget {
  const SundayFajrEditorPage({
    super.key,
    required this.repository,
    required this.actorId,
    required this.eventDate,
    this.now,
  });

  final SundayFajrAttendanceRepository repository;
  final String actorId;
  final DateTime eventDate;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SundayFajrEditorCubit(
        repository: repository,
        actorId: actorId,
        eventDate: eventDate,
        now: now,
      )..load(),
      child: const _SundayFajrEditorView(),
    );
  }
}

class _SundayFajrEditorView extends StatefulWidget {
  const _SundayFajrEditorView();

  @override
  State<_SundayFajrEditorView> createState() => _SundayFajrEditorViewState();
}

class _SundayFajrEditorViewState extends State<_SundayFajrEditorView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SundayFajrEditorCubit, SundayFajrEditorState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == SundayFajrEditorStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Absensi berhasil disimpan.')),
          );
          Navigator.pop(context, true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              action: state.hasRevisionConflict
                  ? SnackBarAction(
                      label: 'Muat ulang',
                      textColor: Colors.white,
                      onPressed: context.read<SundayFajrEditorCubit>().load,
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: const AiwaAppBar(title: 'Absensi Minggu Subuh'),
          body: switch (state.status) {
            SundayFajrEditorStatus.initial ||
            SundayFajrEditorStatus.loading => const _EditorSkeleton(),
            SundayFajrEditorStatus.failure => _EditorError(
              message: state.errorMessage ?? 'Data tidak dapat dimuat.',
              onRetry: context.read<SundayFajrEditorCubit>().load,
            ),
            _ => _buildContent(context, state),
          },
          bottomNavigationBar:
              state.status == SundayFajrEditorStatus.loaded ||
                  state.status == SundayFajrEditorStatus.saving
              ? _buildBottomBar(context, state)
              : null,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SundayFajrEditorState state) {
    final participants = state.participants.where((participant) {
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          participant.santriName.toLowerCase().contains(normalizedQuery) ||
          participant.santriNis.toLowerCase().contains(normalizedQuery);
      final matchesStatus = switch (_statusFilter) {
        'unmarked' => participant.status == null,
        'hadir' => participant.status == SundayFajrAttendanceStatus.hadir,
        'izin' => participant.status == SundayFajrAttendanceStatus.izin,
        'alpha' => participant.status == SundayFajrAttendanceStatus.alpha,
        _ => true,
      };
      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _EditorHeader(state: state),
              const SizedBox(height: 14),
              SundayFajrSummaryRow(
                hadir: state.totalHadir,
                izin: state.totalIzin,
                alpha: state.totalAlpha,
                unmarked: state.totalUnmarked,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar Santri',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (state.isEditable && state.participants.isNotEmpty)
                    TextButton.icon(
                      key: const Key('mark-all-present'),
                      onPressed: state.isBusy
                          ? null
                          : context
                                .read<SundayFajrEditorCubit>()
                                .markAllPresent,
                      icon: const Icon(Icons.done_all_rounded, size: 17),
                      label: const Text(
                        'Semua Hadir',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIS',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    if (state.totalUnmarked > 0)
                      _FilterChip(
                        label: 'Belum (${state.totalUnmarked})',
                        selected: _statusFilter == 'unmarked',
                        onTap: () => setState(() => _statusFilter = 'unmarked'),
                      ),
                    _FilterChip(
                      label: 'Hadir (${state.totalHadir})',
                      selected: _statusFilter == 'hadir',
                      onTap: () => setState(() => _statusFilter = 'hadir'),
                    ),
                    _FilterChip(
                      label: 'Izin (${state.totalIzin})',
                      selected: _statusFilter == 'izin',
                      onTap: () => setState(() => _statusFilter = 'izin'),
                    ),
                    _FilterChip(
                      label: 'Alpha (${state.totalAlpha})',
                      selected: _statusFilter == 'alpha',
                      onTap: () => setState(() => _statusFilter = 'alpha'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (state.participants.isEmpty)
                _NoParticipants(isEditable: state.isEditable)
              else if (participants.isEmpty)
                const _NoSearchResult()
              else
                for (var index = 0; index < participants.length; index++) ...[
                  _ParticipantCard(
                    participant: participants[index],
                    editable: state.isEditable && !state.isBusy,
                    onStatusChanged: (status) => context
                        .read<SundayFajrEditorCubit>()
                        .updateStatus(participants[index].santriId, status),
                    onReasonChanged: (reason) => context
                        .read<SundayFajrEditorCubit>()
                        .updateReason(participants[index].santriId, reason),
                  ),
                  if (index != participants.length - 1)
                    const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, SundayFajrEditorState state) {
    if (!state.isEditable) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data absensi ini sudah terkunci dan hanya dapat dilihat.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!state.allComplete && state.participants.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.totalUnmarked > 0
                          ? '${state.totalUnmarked} santri belum diberi status.'
                          : 'Lengkapi alasan untuk seluruh santri yang izin.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            AiwaButton(
              text: state.isExisting ? 'Simpan Perubahan' : 'Simpan Absensi',
              onPressed: state.canSave
                  ? context.read<SundayFajrEditorCubit>().save
                  : null,
              isLoading: state.status == SundayFajrEditorStatus.saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.state});

  final SundayFajrEditorState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.wb_twilight_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatSundayFajrDate(state.eventDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.isExisting
                      ? '${state.participants.length} peserta - Revisi ${state.attendance!.revision}'
                      : '${state.participants.length} santri memenuhi kriteria',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: state.isEditable
                  ? const Color(0xFFDBEAFE)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.isEditable
                      ? Icons.edit_rounded
                      : Icons.lock_outline_rounded,
                  size: 12,
                  color: state.isEditable
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  state.isEditable ? 'Dapat diedit' : 'Terkunci',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: state.isEditable
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF64748B),
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

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.editable,
    required this.onStatusChanged,
    required this.onReasonChanged,
  });

  final SundayFajrParticipantDraft participant;
  final bool editable;
  final ValueChanged<SundayFajrAttendanceStatus> onStatusChanged;
  final ValueChanged<String> onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final initials = participant.santriName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color:
              participant.status == SundayFajrAttendanceStatus.izin &&
                  !participant.hasValidReason
              ? const Color(0xFFF59E0B)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.santriName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS ${participant.santriNis} - ${participant.kelas}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!editable && participant.status != null)
                SundayFajrStatusBadge(
                  status: participant.status!,
                  compact: true,
                ),
            ],
          ),
          if (editable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final status in SundayFajrAttendanceStatus.values) ...[
                  Expanded(
                    child: _StatusOption(
                      status: status,
                      selected: participant.status == status,
                      onTap: () => onStatusChanged(status),
                    ),
                  ),
                  if (status != SundayFajrAttendanceStatus.values.last)
                    const SizedBox(width: 7),
                ],
              ],
            ),
          ],
          if (participant.status == SundayFajrAttendanceStatus.izin) ...[
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('${participant.santriId}-izin-reason'),
              initialValue: participant.izinReason,
              enabled: editable,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              onChanged: onReasonChanged,
              decoration: InputDecoration(
                hintText: 'Tulis alasan izin',
                counterText: '',
                prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                filled: true,
                fillColor: const Color(0xFFFFFBEB),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: participant.hasValidReason
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: participant.hasValidReason
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
            if (!participant.hasValidReason) ...[
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Alasan izin wajib diisi.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final SundayFajrAttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = SundayFajrStatusStyle.of(status);
    return Material(
      color: selected ? style.background : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? style.color.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                style.icon,
                size: 14,
                color: selected ? style.color : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? style.color : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: const Color(0xFFDBEAFE),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _NoParticipants extends StatelessWidget {
  const _NoParticipants({required this.isEditable});

  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: Icons.groups_outlined,
      title: isEditable ? 'Tidak ada santri wajib' : 'Data tidak ditemukan',
      message: isEditable
          ? 'Belum ada santri aktif putra non-Tahsin yang memenuhi kriteria.'
          : 'Tidak ada absensi tersimpan untuk tanggal ini.',
    );
  }
}

class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.search_off_rounded,
      title: 'Tidak ada hasil',
      message: 'Coba ubah pencarian atau filter status.',
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSkeleton extends StatelessWidget {
  const _EditorSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          height: index == 0 ? 90 : 126,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Text('Memuat data santri dan absensi'),
        ),
      ),
    );
  }
}

class _EditorError extends StatelessWidget {
  const _EditorError({required this.message, required this.onRetry});

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
              Icons.error_outline_rounded,
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
