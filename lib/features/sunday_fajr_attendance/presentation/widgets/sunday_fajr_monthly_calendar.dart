import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_widgets.dart';

/// Batas periode yang boleh ditampilkan pada kalender Minggu Subuh.
///
/// Fitur dimulai pada Agustus 2026. Setelah tersedia, kalender hanya membuka
/// bulan berjalan dan maksimal tiga bulan sebelumnya.
class SundayFajrCalendarPeriod {
  SundayFajrCalendarPeriod._();

  static final DateTime featureStart = DateTime(2026, DateTime.august);

  static List<DateTime> visibleMonths(DateTime now) {
    final currentMonth = DateTime(now.year, now.month);
    if (currentMonth.isBefore(featureStart)) {
      return const [];
    }

    final rollingStart = DateTime(now.year, now.month - 3);
    final firstMonth = rollingStart.isAfter(featureStart)
        ? rollingStart
        : featureStart;

    final result = <DateTime>[];
    for (
      var month = firstMonth;
      !month.isAfter(currentMonth);
      month = DateTime(month.year, month.month + 1)
    ) {
      result.add(month);
    }
    return result;
  }

  static List<DateTime> sundaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysUntilSunday =
        (DateTime.sunday - firstDay.weekday) % DateTime.daysPerWeek;
    final firstSunday = firstDay.add(Duration(days: daysUntilSunday));
    final result = <DateTime>[];

    for (
      var sunday = firstSunday;
      sunday.month == month.month && sunday.year == month.year;
      sunday = sunday.add(const Duration(days: DateTime.daysPerWeek))
    ) {
      result.add(sunday);
    }
    return result;
  }

  static String dateKey(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }
}

/// Kalender ringkas kehadiran Subuh untuk satu santri.
///
/// Widget ini hanya mengurus presentasi dan navigasi bulan. Pengambilan data
/// dan pengecekan hak akses tetap dilakukan oleh parent.
class SundayFajrMonthlyCalendar extends StatefulWidget {
  const SundayFajrMonthlyCalendar({
    super.key,
    required this.history,
    this.now,
    this.showTitle = true,
  });

  final List<SundayFajrParticipant> history;
  final DateTime? now;
  final bool showTitle;

  @override
  State<SundayFajrMonthlyCalendar> createState() =>
      _SundayFajrMonthlyCalendarState();
}

class _SundayFajrMonthlyCalendarState extends State<SundayFajrMonthlyCalendar> {
  static const _monthNames = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _ink = Color(0xFF173B37);

  late List<DateTime> _months;
  late PageController _pageController;
  late int _selectedIndex;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _months = SundayFajrCalendarPeriod.visibleMonths(_now);
    _selectedIndex = _months.isEmpty ? 0 : _months.length - 1;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant SundayFajrMonthlyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextMonths = SundayFajrCalendarPeriod.visibleMonths(_now);
    if (_monthSignature(nextMonths) == _monthSignature(_months)) return;

    final selectedMonth = _months.isEmpty ? null : _months[_selectedIndex];
    _pageController.dispose();
    _months = nextMonths;
    _selectedIndex = selectedMonth == null
        ? (_months.isEmpty ? 0 : _months.length - 1)
        : _months.indexWhere(
            (month) =>
                month.year == selectedMonth.year &&
                month.month == selectedMonth.month,
          );
    if (_selectedIndex < 0) {
      _selectedIndex = _months.isEmpty ? 0 : _months.length - 1;
    }
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_months.isEmpty) return const SizedBox.shrink();

    final month = _months[_selectedIndex];
    final sundayCount = SundayFajrCalendarPeriod.sundaysInMonth(month).length;

    return Column(
      key: const Key('sunday-fajr-monthly-calendar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          const _CalendarTitle(),
          const SizedBox(height: 12),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCEBE8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF134E4A).withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -38,
                top: -46,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCCFBF1).withValues(alpha: 0.55),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MonthNavigationButton(
                          key: const Key('sunday-fajr-calendar-previous'),
                          icon: Icons.chevron_left_rounded,
                          enabled: _selectedIndex > 0,
                          onPressed: () => _goTo(_selectedIndex - 1),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${_monthNames[month.month - 1]} ${month.year}',
                                key: const Key(
                                  'sunday-fajr-calendar-month-title',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$sundayCount hari Minggu',
                                style: const TextStyle(
                                  color: Color(0xFF718783),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _MonthNavigationButton(
                          key: const Key('sunday-fajr-calendar-next'),
                          icon: Icons.chevron_right_rounded,
                          enabled: _selectedIndex < _months.length - 1,
                          onPressed: () => _goTo(_selectedIndex + 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const Divider(height: 1, color: Color(0xFFE8F1EF)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 113,
                      child: PageView.builder(
                        key: const Key('sunday-fajr-calendar-page-view'),
                        controller: _pageController,
                        itemCount: _months.length,
                        onPageChanged: (index) {
                          if (_selectedIndex == index) return;
                          setState(() => _selectedIndex = index);
                        },
                        itemBuilder: (context, index) => _MonthWeeks(
                          month: _months[index],
                          statusByDate: _statusByDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _CalendarLegend(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, SundayFajrAttendanceStatus> get _statusByDate {
    final result = <String, SundayFajrAttendanceStatus>{};
    for (final participant in widget.history) {
      result.putIfAbsent(
        SundayFajrCalendarPeriod.dateKey(participant.eventDate),
        () => participant.status,
      );
    }
    return result;
  }

  void _goTo(int index) {
    if (index < 0 || index >= _months.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  static String _monthSignature(List<DateTime> months) {
    return months.map((month) => '${month.year}-${month.month}').join('|');
  }
}

class _CalendarTitle extends StatelessWidget {
  const _CalendarTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Absensi Minggu Subuh',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _MonthNavigationButton extends StatelessWidget {
  const _MonthNavigationButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 21),
      color: const Color(0xFF0F766E),
      disabledColor: const Color(0xFFCBD8D5),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    );
  }
}

class _MonthWeeks extends StatelessWidget {
  const _MonthWeeks({required this.month, required this.statusByDate});

  final DateTime month;
  final Map<String, SundayFajrAttendanceStatus> statusByDate;

  @override
  Widget build(BuildContext context) {
    final sundays = SundayFajrCalendarPeriod.sundaysInMonth(month);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < sundays.length; index++) ...[
          Expanded(
            child: _WeekTile(
              index: index,
              date: sundays[index],
              status:
                  statusByDate[SundayFajrCalendarPeriod.dateKey(
                    sundays[index],
                  )],
            ),
          ),
          if (index < sundays.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.index,
    required this.date,
    required this.status,
  });

  final int index;
  final DateTime date;
  final SundayFajrAttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final style = status == null
        ? const SundayFajrStatusStyle(
            color: Color(0xFF64748B),
            background: Color(0xFFF1F5F9),
            icon: Icons.horizontal_rule_rounded,
          )
        : SundayFajrStatusStyle.of(status!);

    return Container(
      key: Key('sunday-fajr-week-${SundayFajrCalendarPeriod.dateKey(date)}'),
      padding: const EdgeInsets.fromLTRB(3, 7, 3, 6),
      decoration: BoxDecoration(
        color: style.background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: style.color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MINGGU ${index + 1}',
            maxLines: 1,
            style: TextStyle(
              color: style.color.withValues(alpha: 0.78),
              fontSize: 7.8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: const TextStyle(
              color: Color(0xFF173B37),
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Icon(style.icon, color: style.color, size: 19),
          const SizedBox(height: 3),
          Text(
            status?.label ?? 'Belum',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              color: style.color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 5,
      children: [
        _LegendItem(color: Color(0xFF15803D), label: 'Hadir'),
        _LegendItem(color: Color(0xFFB45309), label: 'Izin'),
        _LegendItem(color: Color(0xFFB91C1C), label: 'Alpha'),
        _LegendItem(color: Color(0xFF64748B), label: 'Belum dicatat'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
