import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_state.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/widgets/santri_attendance_content.dart';

class SantriAttendancePage extends StatelessWidget {
  final ActiveHalaqah activeHalaqah;

  const SantriAttendancePage({super.key, required this.activeHalaqah});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              activeHalaqah.halaqah.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat(
                'EEEE, d MMMM • HH:mm',
                'id_ID',
              ).format(DateTime.now()),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<SantriAttendanceCubit, SantriAttendanceState>(
        listener: (context, state) {
          if (state is SantriAttendanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Absensi berhasil disimpan'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is SantriAttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SantriAttendanceLoading) {
            return const SantriAttendanceSkeleton();
          }

          if (state is! SantriAttendanceLoaded) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              if (state.isExistingData)
                ExistingAttendanceInfo(lastUpdated: state.lastUpdated),
              Expanded(
                child: SantriAttendanceList(
                  santris: state.santris,
                  attendanceMap: state.attendanceMap,
                  activeHalaqahId: activeHalaqah.halaqah.id,
                  onStatusChanged: context
                      .read<SantriAttendanceCubit>()
                      .updateAttendance,
                ),
              ),
              AttendanceSubmitBar(
                isSubmitting: state.isSubmitting,
                onSubmit: context
                    .read<SantriAttendanceCubit>()
                    .submitAttendance,
              ),
            ],
          );
        },
      ),
    );
  }
}
