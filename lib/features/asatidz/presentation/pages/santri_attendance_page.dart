import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_outline_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_state.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
            return _buildSkeletonList();
          }

          if (state is SantriAttendanceLoaded) {
            return Column(
              children: [
                if (state.isExistingData)
                  _buildExistingDataInfo(state.lastUpdated),
                Expanded(child: _buildAttendanceList(context, state)),
                _buildSubmitButton(context, state),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 90,
                          height: 12,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingDataInfo(DateTime? lastUpdated) {
    final dateStr = lastUpdated != null
        ? DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(lastUpdated)
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sudah melakukan absen',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Terakhir: $dateStr',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    BuildContext context,
    SantriAttendanceLoaded state,
  ) {
    final santris = state.santris;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: santris.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final santri = santris[index];
        final status = state.attendanceMap[santri.id] ?? 'hadir';
        final initial = santri.name.isNotEmpty
            ? santri.name[0].toUpperCase()
            : '?';
        final isGuest = santri.halaqahId != activeHalaqah.halaqah.id;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                      Row(
                        children: [
                          Text(
                            'NIS: ${santri.nis}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (isGuest) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                'Tamu',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
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
        color: (config['color'] as Color).withValues(alpha: 0.1),
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

  Widget _buildStatusToggle(
    BuildContext context,
    String santriId,
    String currentStatus,
  ) {
    final isPresent = currentStatus == 'hadir';

    return GestureDetector(
      onTap: () {
        if (isPresent) {
          _showStatusBottomSheet(context, santriId);
        } else {
          context.read<SantriAttendanceCubit>().updateAttendance(
            santriId,
            'hadir',
          );
        }
      },
      child: Column(
        children: [
          Container(
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
                  alignment: isPresent
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
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
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPresent ? 'Hadir' : 'Absent',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPresent ? Colors.blue : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusBottomSheet(BuildContext context, String santriId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alasan Tidak Hadir',
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
                'Sakit',
                'sakit',
                Icons.local_hospital,
                Colors.blue,
              ),
              const Divider(height: 1),
              _buildReasonOption(
                context,
                santriId,
                'Izin',
                'izin',
                Icons.info,
                Colors.orange,
              ),
              const Divider(height: 1),
              _buildReasonOption(
                context,
                santriId,
                'Alpha',
                'alpha',
                Icons.cancel,
                Colors.red,
              ),
              const SizedBox(height: 16),
              AiwaOutlineButton(
                text: 'Batal',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
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
        context.read<SantriAttendanceCubit>().updateAttendance(
          santriId,
          status,
        );
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    SantriAttendanceLoaded state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: AiwaButton(
          text: 'Simpan Absensi',
          isLoading: state.isSubmitting,
          onPressed: () {
            context.read<SantriAttendanceCubit>().submitAttendance();
          },
        ),
      ),
    );
  }
}
