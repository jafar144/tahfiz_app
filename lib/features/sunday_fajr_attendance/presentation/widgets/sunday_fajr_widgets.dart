import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';

class SundayFajrStatusStyle {
  const SundayFajrStatusStyle({
    required this.color,
    required this.background,
    required this.icon,
  });

  final Color color;
  final Color background;
  final IconData icon;

  static SundayFajrStatusStyle of(SundayFajrAttendanceStatus status) {
    return switch (status) {
      SundayFajrAttendanceStatus.hadir => const SundayFajrStatusStyle(
        color: Color(0xFF15803D),
        background: Color(0xFFDCFCE7),
        icon: Icons.check_circle_rounded,
      ),
      SundayFajrAttendanceStatus.izin => const SundayFajrStatusStyle(
        color: Color(0xFFB45309),
        background: Color(0xFFFEF3C7),
        icon: Icons.info_rounded,
      ),
      SundayFajrAttendanceStatus.alpha => const SundayFajrStatusStyle(
        color: Color(0xFFB91C1C),
        background: Color(0xFFFEE2E2),
        icon: Icons.cancel_rounded,
      ),
    };
  }
}

class SundayFajrStatusBadge extends StatelessWidget {
  const SundayFajrStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final SundayFajrAttendanceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = SundayFajrStatusStyle.of(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 13 : 15, color: style.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: style.color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SundayFajrSummaryRow extends StatelessWidget {
  const SundayFajrSummaryRow({
    super.key,
    required this.hadir,
    required this.izin,
    required this.alpha,
    this.unmarked = 0,
  });

  final int hadir;
  final int izin;
  final int alpha;
  final int unmarked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Hadir',
            value: hadir,
            color: const Color(0xFF15803D),
            background: const Color(0xFFF0FDF4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Izin',
            value: izin,
            color: const Color(0xFFB45309),
            background: const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Alpha',
            value: alpha,
            color: const Color(0xFFB91C1C),
            background: const Color(0xFFFEF2F2),
          ),
        ),
        if (unmarked > 0) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              label: 'Belum',
              value: unmarked,
              color: const Color(0xFF64748B),
              background: const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: color.withValues(alpha: 0.82),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String formatSundayFajrDate(
  DateTime date, {
  String pattern = 'EEEE, d MMMM yyyy',
}) {
  return DateFormat(pattern, 'id_ID').format(date);
}
