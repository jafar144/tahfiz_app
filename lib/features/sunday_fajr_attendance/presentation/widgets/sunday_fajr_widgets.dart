import 'dart:math' as math;

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

class SundayFajrAttendanceChart extends StatelessWidget {
  const SundayFajrAttendanceChart({
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
    final total = hadir + izin + alpha + unmarked;
    final items = <_ChartItem>[
      _ChartItem(label: 'Hadir', value: hadir, color: const Color(0xFF22A447)),
      _ChartItem(label: 'Izin', value: izin, color: const Color(0xFFF59E0B)),
      _ChartItem(label: 'Alpha', value: alpha, color: const Color(0xFFEF4444)),
      if (unmarked > 0)
        _ChartItem(
          label: 'Belum diisi',
          value: unmarked,
          color: const Color(0xFFCBD5E1),
        ),
    ];

    return Semantics(
      label:
          'Ringkasan absensi: $hadir hadir, $izin izin, $alpha alpha'
          '${unmarked > 0 ? ', $unmarked belum diisi' : ''}.',
      child: Container(
        key: const Key('sunday-fajr-attendance-chart'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Kehadiran',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Komposisi absensi santri Minggu Subuh',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(132),
                        painter: _AttendanceDonutPainter(
                          items: items,
                          total: total,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 24,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'santri',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _ChartLegendItem(item: items[index], total: total),
                        if (index != items.length - 1)
                          const SizedBox(height: 11),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SundayFajrDistributionBar extends StatelessWidget {
  const SundayFajrDistributionBar({
    super.key,
    required this.hadir,
    required this.izin,
    required this.alpha,
  });

  final int hadir;
  final int izin;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    final total = hadir + izin + alpha;
    if (total == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (hadir > 0)
              Expanded(
                flex: hadir,
                child: const ColoredBox(color: Color(0xFF22A447)),
              ),
            if (izin > 0)
              Expanded(
                flex: izin,
                child: const ColoredBox(color: Color(0xFFF59E0B)),
              ),
            if (alpha > 0)
              Expanded(
                flex: alpha,
                child: const ColoredBox(color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartItem {
  const _ChartItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({required this.item, required this.total});

  final _ChartItem item;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (item.value * 100 / total).round();
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${item.value}',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 30,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceDonutPainter extends CustomPainter {
  const _AttendanceDonutPainter({required this.items, required this.total});

  final List<_ChartItem> items;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 18) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 15.0;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF1F5F9);
    canvas.drawCircle(center, radius, trackPaint);
    if (total == 0) return;

    const gap = 0.045;
    var startAngle = -math.pi / 2;
    for (final item in items) {
      if (item.value <= 0) continue;
      final fullSweep = 2 * math.pi * item.value / total;
      final visibleSweep = math.max(0.0, fullSweep - gap);
      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;
      canvas.drawArc(bounds, startAngle, visibleSweep, false, segmentPaint);
      startAngle += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AttendanceDonutPainter oldDelegate) {
    if (oldDelegate.total != total ||
        oldDelegate.items.length != items.length) {
      return true;
    }
    for (var index = 0; index < items.length; index++) {
      if (oldDelegate.items[index].value != items[index].value ||
          oldDelegate.items[index].color != items[index].color) {
        return true;
      }
    }
    return false;
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
