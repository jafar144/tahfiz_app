import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_state.dart';

class ScheduleViewPage extends StatelessWidget {
  const ScheduleViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
          List<ProgramSchedule> schedules = [];
          List<ScheduleProgram> programs = [];

          if (state is ScheduleLoaded) {
            selectedGender = state.selectedGender;
            halaqahs = state.halaqahs;
            schedules = state.schedules;
            programs = state.programs;
          } else if (isLoading) {
            selectedGender = 'L'; // Default for skeleton
            halaqahs = List.generate(
              5,
              (index) => const Halaqah(
                id: 'dummy',
                programId: 'dummy',
                scheduleIds: [],
                name: 'Halaqah Dummy',
                room: 'Ruang A',
                teacherId: 'teacher',
                teacherName: 'Ustadz Fulan',
                status: 'Active',
                santris: [],
              ),
            );
          }

          return Skeletonizer(
            enabled: isLoading,
            child: Column(
              children: [
                _buildGenderSelector(context, selectedGender),
                Expanded(
                  child: _buildHalaqahList(schedules, halaqahs, programs),
                ),
              ],
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

  Widget _buildHalaqahList(
      List<ProgramSchedule> schedules,
      List<Halaqah> halaqahs,
      List<ScheduleProgram> programs) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: halaqahs.length,
      itemBuilder: (context, index) {
        final halaqah = halaqahs[index];
        return _buildHalaqahCard(context, halaqah, schedules, programs);
      },
    );
  }

  String _dayName(int day) {
    if (day == 0) return 'Invalid';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }

  Widget _buildHalaqahCard(
      BuildContext context,
      Halaqah halaqah,
      List<ProgramSchedule> allSchedules,
      List<ScheduleProgram> programs) {
    final halaqahSchedules =
        allSchedules.where((s) => halaqah.scheduleIds.contains(s.id)).toList();

    final cubit = context.read<ScheduleCubit>();
    final currentState = cubit.state;
    final gender =
        currentState is ScheduleLoaded ? currentState.selectedGender : 'L';
    final borderColor = gender == 'L' ? Colors.blue : Colors.pink;
    final initial = halaqah.name.isNotEmpty
        ? (halaqah.name.length >= 2
            ? halaqah.name.substring(0, 2).toUpperCase()
            : halaqah.name[0].toUpperCase())
        : '?';

    // Determine session from program/session ID
    final program = programs.cast<ScheduleProgram>().firstWhere(
      (p) => p.id == halaqah.programId,
      orElse: () => const ScheduleProgram(id: '', name: 'Regular', gender: ''),
    );
    final session = program.name.isNotEmpty ? program.name : 'Regular';

    return InkWell(
      onTap: () async {
        await context.pushNamed(
          RouteNames.detailHalaqah,
          extra: {
            'halaqah': halaqah,
            'sessionName': session,
            'gender': gender,
          },
        );
        if (context.mounted) {
          final currentGender =
              context.read<ScheduleCubit>().state is ScheduleLoaded
                  ? (context.read<ScheduleCubit>().state as ScheduleLoaded)
                      .selectedGender
                  : 'L';
          context.read<ScheduleCubit>().loadSchedule(currentGender);
        }
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Initial Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Header Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                halaqah.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Session Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getSessionColor(session).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getSessionIcon(session),
                                    size: 14,
                                    color: _getSessionColor(session),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    session,
                                    style: TextStyle(
                                      color: _getSessionColor(session),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ruang ${halaqah.room}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Teacher, Santri Count, and Gender Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          halaqah.teacherName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${halaqah.santris.length} Santri',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gender == 'L' ? 'Putra' : 'Putri',
                      style: TextStyle(
                        fontSize: 11,
                        color: borderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (halaqahSchedules.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'JADWAL SESI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...halaqahSchedules.map((schedule) {
                  final dayName = _dayName(schedule.day);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${schedule.startTime}  -  ${schedule.endTime}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
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
