import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_monthly_calendar.dart';

void main() {
  group('SundayFajrCalendarPeriod', () {
    test('tidak membuka periode sebelum Agustus 2026', () {
      expect(
        SundayFajrCalendarPeriod.visibleMonths(DateTime(2026, 7, 31)),
        isEmpty,
      );
    });

    test('dimulai Agustus dan tidak membuka bulan masa depan', () {
      final months = SundayFajrCalendarPeriod.visibleMonths(
        DateTime(2026, 8, 3),
      );

      expect(_monthKeys(months), ['2026-08']);
    });

    test('membatasi navigasi ke bulan berjalan dan tiga bulan sebelumnya', () {
      final months = SundayFajrCalendarPeriod.visibleMonths(
        DateTime(2027, 2, 15),
      );

      expect(_monthKeys(months), ['2026-11', '2026-12', '2027-01', '2027-02']);
    });

    test('menghasilkan seluruh hari Minggu pada bulan terpilih', () {
      final sundays = SundayFajrCalendarPeriod.sundaysInMonth(
        DateTime(2026, 8),
      );

      expect(sundays.map((date) => date.day), [2, 9, 16, 23, 30]);
      expect(sundays.every((date) => date.weekday == DateTime.sunday), isTrue);
    });
  });

  testWidgets('menampilkan satu kotak per Minggu beserta statusnya', (
    tester,
  ) async {
    final history = [
      _participant(DateTime.utc(2026, 8, 2), SundayFajrAttendanceStatus.hadir),
      _participant(DateTime.utc(2026, 8, 9), SundayFajrAttendanceStatus.izin),
      _participant(DateTime.utc(2026, 8, 16), SundayFajrAttendanceStatus.alpha),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SundayFajrMonthlyCalendar(
              history: history,
              now: DateTime(2026, 8, 20),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Kehadiran Minggu Subuh'), findsOneWidget);
    expect(find.text('Agustus 2026'), findsOneWidget);
    expect(find.text('5 hari Minggu'), findsOneWidget);
    for (final day in [2, 9, 16, 23, 30]) {
      expect(
        find.byKey(Key('sunday-fajr-week-2026-08-${_twoDigits(day)}')),
        findsOneWidget,
      );
    }
    expect(_statusInWeek('2026-08-02', 'Hadir'), findsOneWidget);
    expect(_statusInWeek('2026-08-09', 'Izin'), findsOneWidget);
    expect(_statusInWeek('2026-08-16', 'Alpha'), findsOneWidget);
    expect(_statusInWeek('2026-08-23', 'Belum'), findsOneWidget);
  });

  testWidgets('dapat digeser tanpa melewati tiga bulan sebelumnya', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SundayFajrMonthlyCalendar(
              history: const [],
              now: DateTime(2026, 12, 12),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Desember 2026'), findsOneWidget);
    final nextButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const Key('sunday-fajr-calendar-next')),
        matching: find.byType(IconButton),
      ),
    );
    expect(nextButton.onPressed, isNull);

    await tester.drag(
      find.byKey(const Key('sunday-fajr-calendar-page-view')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('sunday-fajr-calendar-previous')));
      await tester.pumpAndSettle();
    }
    expect(find.text('September 2026'), findsOneWidget);

    final previousButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const Key('sunday-fajr-calendar-previous')),
        matching: find.byType(IconButton),
      ),
    );
    expect(previousButton.onPressed, isNull);
    expect(find.text('Agustus 2026'), findsNothing);
  });

  testWidgets('tidak merender kalender sebelum fitur dimulai', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SundayFajrMonthlyCalendar(
          history: const [],
          now: DateTime(2026, 7, 31),
        ),
      ),
    );

    expect(find.byKey(const Key('sunday-fajr-monthly-calendar')), findsNothing);
  });
}

List<String> _monthKeys(List<DateTime> months) {
  return months
      .map((month) => '${month.year}-${_twoDigits(month.month)}')
      .toList();
}

Finder _statusInWeek(String weekKey, String label) {
  return find.descendant(
    of: find.byKey(Key('sunday-fajr-week-$weekKey')),
    matching: find.text(label),
  );
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

SundayFajrParticipant _participant(
  DateTime eventDate,
  SundayFajrAttendanceStatus status,
) {
  final weekKey = SundayFajrCalendarPeriod.dateKey(eventDate);
  return SundayFajrParticipant(
    id: 'santri-1',
    santriId: 'santri-1',
    santriName: 'Ahmad',
    santriNis: '101',
    kelas: 'Tahfiz 1',
    weekKey: weekKey,
    eventDate: eventDate,
    status: status,
    createdAt: eventDate,
    updatedAt: eventDate,
  );
}
