import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_state.dart';

class ScheduleViewPage extends StatelessWidget {
  const ScheduleViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text(
          'Manajemen Halaqah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleError) {
            return Center(child: Text(state.message));
          }

          final isLoading = state is ScheduleLoading;
          String selectedGender = 'L';
          List<Halaqah> halaqahs = [];
          List<ScheduleProgram> programs = [];

          if (state is ScheduleLoaded) {
            selectedGender = state.selectedGender;
            halaqahs = state.halaqahs;
            programs = state.programs;
          } else if (isLoading) {
            selectedGender = 'L'; // Default for skeleton
            halaqahs = List.generate(
              5,
              (index) => Halaqah(
                id: 'dummy_$index',
                programId: 'dummy',
                scheduleIds: const [],
                name: 'Halaqah Dummy',
                room: 'A',
                teacherId: 'teacher_$index',
                teacherName: 'Ustadz Fulan',
                status: 'Active',
                santriCount: 12,
              ),
            );
          }

          return Skeletonizer(
            enabled: isLoading,
            child: SafeArea(
              child: Column(
                children: [
                _buildGenderSelector(context, selectedGender),
                Expanded(
                  child: _buildAsatidzList(
                      context, selectedGender, halaqahs, programs),
                ),
              ],
            ),
          ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushNamed(RouteNames.addHalaqah);
          if (context.mounted) {
            final cubit = context.read<ScheduleCubit>();
            final currentState = cubit.state;
            if (currentState is ScheduleLoaded) {
              cubit.loadSchedule(currentState.selectedGender);
            }
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGenderSelector(BuildContext context, String selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildGenderOption(context, 'Kelas Putra', 'L', selected),
          _buildGenderOption(context, 'Kelas Putri', 'P', selected),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
      BuildContext context, String label, String value, String selected) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            context.read<ScheduleCubit>().loadSchedule(value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (value == 'P' ? Colors.red : Colors.blue)
                  : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAsatidzList(
    BuildContext context,
    String gender,
    List<Halaqah> halaqahs,
    List<ScheduleProgram> programs,
  ) {
    if (halaqahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada halaqah',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan halaqah baru dengan\nmenekan tombol + di bawah',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Kelompokkan halaqah per pengajar (urut sesuai kemunculan).
    final order = <String>[];
    final byTeacher = <String, List<Halaqah>>{};
    for (final h in halaqahs) {
      if (!byTeacher.containsKey(h.teacherId)) {
        byTeacher[h.teacherId] = [];
        order.add(h.teacherId);
      }
      byTeacher[h.teacherId]!.add(h);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: order.length,
      itemBuilder: (context, index) {
        final teacherId = order[index];
        final group = byTeacher[teacherId]!;
        return _buildAsatidzCard(context, gender, teacherId, group, programs);
      },
    );
  }

  Widget _buildAsatidzCard(
    BuildContext context,
    String gender,
    String teacherId,
    List<Halaqah> halaqahs,
    List<ScheduleProgram> programs,
  ) {
    final accent = gender == 'L' ? Colors.blue : Colors.pink;
    final teacherName = halaqahs.isNotEmpty ? halaqahs.first.teacherName : '-';
    final totalSantri = halaqahs.fold<int>(0, (sum, h) => sum + h.santriCount);

    // Sesi unik (terurut pagi→sore→malam) untuk badge overview.
    String sessionOf(Halaqah h) {
      final program = programs.cast<ScheduleProgram?>().firstWhere(
            (p) => p?.id == h.programId,
            orElse: () => null,
          );
      final name =
          (program?.name.isNotEmpty ?? false) ? program!.name : 'Regular';
      return _capitalize(name);
    }

    final sessions = <String>[];
    for (final h in halaqahs) {
      final s = sessionOf(h);
      if (!sessions.contains(s)) sessions.add(s);
    }
    const sOrder = {'Pagi': 0, 'Sore': 1, 'Malam': 2};
    sessions.sort((a, b) => (sOrder[a] ?? 99).compareTo(sOrder[b] ?? 99));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.pushNamed(
              RouteNames.detailAsatidzHalaqah,
              extra: {
                'teacherId': teacherId,
                'teacherName': teacherName,
                'gender': gender,
              },
            );
            if (context.mounted) {
              final cubit = context.read<ScheduleCubit>();
              final st = cubit.state;
              if (st is ScheduleLoaded) cubit.loadSchedule(st.selectedGender);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    UiUtils.getInitials(teacherName),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${halaqahs.length} halaqah · $totalSantri santri',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: sessions.map(_sessionBadge).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sessionBadge(String session) {
    final color = _getSessionColor(session);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSessionIcon(session), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            session,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getSessionColor(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Colors.blue;
      case 'sore':
        return Colors.orange.shade700;
      case 'malam':
        return Colors.indigo.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getSessionIcon(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Icons.wb_sunny;
      case 'sore':
        return Icons.wb_twilight;
      case 'malam':
        return Icons.nights_stay;
      default:
        return Icons.schedule;
    }
  }
}
