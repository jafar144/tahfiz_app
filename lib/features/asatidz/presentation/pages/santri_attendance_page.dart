import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_state.dart';
import 'package:intl/intl.dart';

class SantriAttendancePage extends StatelessWidget {
  final ActiveHalaqah activeHalaqah;

  const SantriAttendancePage({
    super.key,
    required this.activeHalaqah,
  });

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
              DateFormat('EEEE, d MMMM • HH:mm', 'id_ID').format(DateTime.now()),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
          }
          if (state is SantriAttendanceError) {
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
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SantriAttendanceLoaded) {
            return Column(
              children: [
                Expanded(
                  child: _buildAttendanceList(context, state),
                ),
                _buildSubmitButton(context, state),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context, SantriAttendanceLoaded state) {
    final santris = activeHalaqah.halaqah.santris;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: santris.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final santri = santris[index];
        final status = state.attendanceMap[santri.id] ?? 'hadir';
        final initial = santri.name.isNotEmpty ? santri.name[0].toUpperCase() : '?';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        santri.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIS: ${santri.nis}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (status != 'hadir') ...[
                        const SizedBox(height: 4),
                        _buildReasonChip(status),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusToggle(context, santri.id, status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReasonChip(String status) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      'izin': {'label': 'Izin', 'color': Colors.orange},
      'sakit': {'label': 'Sakit', 'color': Colors.blue},
      'alpha': {'label': 'Alpha', 'color': Colors.red},
    };

    final config = statusConfig[status];
    if (config == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config['color'],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(BuildContext context, String santriId, String currentStatus) {
    final isPresent = currentStatus == 'hadir';

    return GestureDetector(
      onTap: () {
        if (isPresent) {
          _showStatusBottomSheet(context, santriId);
        } else {
          context.read<SantriAttendanceCubit>().updateAttendance(santriId, 'hadir');
        }
      },
      child: Container(
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          color: isPresent ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isPresent ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(left: isPresent ? 6 : 0, right: isPresent ? 0 : 6),
                child: Text(
                  isPresent ? 'Hadir' : 'Absent',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPresent ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusBottomSheet(BuildContext context, String santriId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REASON FOR ABSENCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            _buildReasonOption(
              context,
              santriId,
              'Sakit (Sick)',
              'sakit',
              Icons.local_hospital,
              Colors.blue,
            ),
            const Divider(height: 1),
            _buildReasonOption(
              context,
              santriId,
              'Izin (Permission)',
              'izin',
              Icons.info,
              Colors.orange,
            ),
            const Divider(height: 1),
            _buildReasonOption(
              context,
              santriId,
              'Alpha (Absent)',
              'alpha',
              Icons.cancel,
              Colors.red,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(
    BuildContext context,
    String santriId,
    String label,
    String status,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        context.read<SantriAttendanceCubit>().updateAttendance(santriId, status);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, SantriAttendanceLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () {
                    context.read<SantriAttendanceCubit>().submitAttendance();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Submit Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
