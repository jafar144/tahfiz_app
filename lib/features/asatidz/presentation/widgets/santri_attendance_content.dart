import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_outline_button.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:skeletonizer/skeletonizer.dart';

typedef AttendanceStatusChanged = void Function(String santriId, String status);

enum _AttendanceStatus {
  hadir('hadir', 'Hadir', Colors.blue, Icons.check_circle),
  sakit('sakit', 'Sakit', Colors.blue, Icons.local_hospital),
  izin('izin', 'Izin', Colors.orange, Icons.info),
  alpha('alpha', 'Alpha', Colors.red, Icons.cancel);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _AttendanceStatus(this.value, this.label, this.color, this.icon);

  static _AttendanceStatus fromValue(String value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => hadir,
    );
  }
}

class SantriAttendanceSkeleton extends StatelessWidget {
  const SantriAttendanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
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
      ),
    );
  }
}

class ExistingAttendanceInfo extends StatelessWidget {
  final DateTime? lastUpdated;

  const ExistingAttendanceInfo({super.key, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final formattedDate = lastUpdated == null
        ? null
        : DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(lastUpdated!);

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
                if (formattedDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Terakhir: $formattedDate',
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
}

class SantriAttendanceList extends StatelessWidget {
  final List<SantriEntity> santris;
  final Map<String, String> attendanceMap;
  final String activeHalaqahId;
  final AttendanceStatusChanged onStatusChanged;

  const SantriAttendanceList({
    super.key,
    required this.santris,
    required this.attendanceMap,
    required this.activeHalaqahId,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: santris.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final santri = santris[index];
        return _SantriAttendanceCard(
          santri: santri,
          status: _AttendanceStatus.fromValue(
            attendanceMap[santri.id] ?? _AttendanceStatus.hadir.value,
          ),
          isGuest: santri.halaqahId != activeHalaqahId,
          onStatusChanged: (status) => onStatusChanged(santri.id, status.value),
        );
      },
    );
  }
}

class _SantriAttendanceCard extends StatelessWidget {
  final SantriEntity santri;
  final _AttendanceStatus status;
  final bool isGuest;
  final ValueChanged<_AttendanceStatus> onStatusChanged;

  const _SantriAttendanceCard({
    required this.santri,
    required this.status,
    required this.isGuest,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final initial = santri.name.isEmpty ? '?' : santri.name[0].toUpperCase();

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                      const _GuestBadge(),
                    ],
                  ],
                ),
                if (status != _AttendanceStatus.hadir) ...[
                  const SizedBox(height: 4),
                  _ReasonChip(status: status),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AttendanceStatusToggle(
            status: status,
            onStatusChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _GuestBadge extends StatelessWidget {
  const _GuestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        'Tamu',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final _AttendanceStatus status;

  const _ReasonChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _AttendanceStatusToggle extends StatelessWidget {
  final _AttendanceStatus status;
  final ValueChanged<_AttendanceStatus> onStatusChanged;

  const _AttendanceStatusToggle({
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == _AttendanceStatus.hadir;

    return GestureDetector(
      onTap: () {
        if (isPresent) {
          _showReasonSheet(context);
        } else {
          onStatusChanged(_AttendanceStatus.hadir);
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
            child: AnimatedAlign(
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

  void _showReasonSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
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
              for (final reason in const [
                _AttendanceStatus.sakit,
                _AttendanceStatus.izin,
                _AttendanceStatus.alpha,
              ]) ...[
                _ReasonOption(
                  status: reason,
                  onTap: () {
                    onStatusChanged(reason);
                    Navigator.pop(sheetContext);
                  },
                ),
                if (reason != _AttendanceStatus.alpha) const Divider(height: 1),
              ],
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
}

class _ReasonOption extends StatelessWidget {
  final _AttendanceStatus status;
  final VoidCallback onTap;

  const _ReasonOption({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(status.icon, color: status.color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              status.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceSubmitBar extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const AttendanceSubmitBar({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
          isLoading: isSubmitting,
          onPressed: onSubmit,
        ),
      ),
    );
  }
}
