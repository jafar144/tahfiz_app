import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_state.dart';

class ScheduleViewPage extends StatelessWidget {
  const ScheduleViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text(
          'Manajemen Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ScheduleError) {
            return Center(child: Text(state.message));
          }
          if (state is ScheduleLoaded) {
            return Column(
              children: [
                _buildGenderSelector(context, state.selectedGender),
                Expanded(
                  child: _buildScheduleList(state.schedules, state.halaqahs),
                ),
              ],
            );
          }
          return const SizedBox();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          _buildChip(context, 'Kelas Putra', selected == 'L'),
          const SizedBox(width: 12),
          _buildChip(context, 'Kelas Putri', selected == 'P'),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
         final gender = label.contains('Putra') ? 'L' : 'P';
         context.read<ScheduleCubit>().loadSchedule(gender);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade50,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildScheduleList(
      List<ProgramSchedule> schedules, List<Halaqah> halaqahs) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada jadwal',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
             const Text(
              'Pastikan data sessions, schedules,\ndan halaqah sudah diinput.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = index + 1;
        final daySchedules = schedules.where((s) => s.day == day).toList();

        if (daySchedules.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    _dayName(day),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ...daySchedules.expand((schedule) {
              final classHalaqahs =
                  halaqahs.where((h) => h.scheduleId == schedule.id); // Matched by Schedule ID
              return classHalaqahs.map((h) => _buildHalaqahCard(context, h, schedule));
            }),
          ],
        );
      },
    );
  }

  String _dayName(int day) {
    if (day == 0) return 'JADWAL TIDAK VALID';
    const days = [
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
      'MINGGU'
    ];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }

  Widget _buildHalaqahCard(BuildContext context, Halaqah halaqah, ProgramSchedule schedule) {
    return InkWell(
      onTap: () async {
        await context.pushNamed(RouteNames.detailHalaqah, extra: halaqah);
        if (context.mounted) {
           final gender = context.read<ScheduleCubit>().state is ScheduleLoaded 
              ? (context.read<ScheduleCubit>().state as ScheduleLoaded).selectedGender
              : 'L';
           context.read<ScheduleCubit>().loadSchedule(gender);
        }
      },
      child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        halaqah.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${schedule.startTime} - ${schedule.endTime}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, size: 20, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(halaqah.teacherName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: halaqah.status == 'Active'
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    halaqah.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: halaqah.status == 'Active'
                          ? Colors.green
                          : Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
    );
  }
}
