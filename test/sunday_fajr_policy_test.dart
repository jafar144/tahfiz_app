import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_eligibility.dart';

void main() {
  group('SundayFajrAttendancePolicy', () {
    test('pergantian hari mengikuti WIB, bukan UTC', () {
      final beforeSundayWib = DateTime.utc(2026, 7, 25, 16, 59);
      final startOfSundayWib = DateTime.utc(2026, 7, 25, 17);

      expect(
        SundayFajrAttendancePolicy.latestSunday(now: beforeSundayWib),
        DateTime.utc(2026, 7, 19),
      );
      expect(
        SundayFajrAttendancePolicy.latestSunday(now: startOfSundayWib),
        DateTime.utc(2026, 7, 26),
      );
    });

    test('record hanya editable pada hari Minggu yang sama', () {
      final sundayNow = DateTime.utc(2026, 7, 26, 5);
      final mondayNow = DateTime.utc(2026, 7, 27, 5);

      expect(
        SundayFajrAttendancePolicy.isEditable(
          DateTime.utc(2026, 7, 26),
          now: sundayNow,
        ),
        isTrue,
      );
      expect(
        SundayFajrAttendancePolicy.isEditable(
          DateTime.utc(2026, 7, 19),
          now: sundayNow,
        ),
        isFalse,
      );
      expect(
        SundayFajrAttendancePolicy.isEditable(
          DateTime.utc(2026, 7, 26),
          now: mondayNow,
        ),
        isFalse,
      );
      expect(
        SundayFajrAttendancePolicy.isEditable(
          DateTime.utc(2026, 8, 2),
          now: sundayNow,
        ),
        isFalse,
      );
    });

    test('create hanya boleh dilakukan pada hari Minggu WIB yang sama', () {
      final sundayWib = DateTime.utc(2026, 7, 26, 5);
      final mondayWib = DateTime.utc(2026, 7, 27, 5);
      final sunday = DateTime.utc(2026, 7, 26);

      expect(
        SundayFajrAttendancePolicy.canCreate(sunday, now: sundayWib),
        isTrue,
      );
      expect(
        SundayFajrAttendancePolicy.canCreate(sunday, now: mondayWib),
        isFalse,
      );
      expect(
        SundayFajrAttendancePolicy.canCreate(
          DateTime.utc(2026, 7, 19),
          now: sundayWib,
        ),
        isFalse,
      );
    });

    test('batas transaksi menerima 497 dan menolak 498 peserta', () {
      expect(SundayFajrAttendancePolicy.isRosterSizeSupported(497), isTrue);
      expect(SundayFajrAttendancePolicy.isRosterSizeSupported(498), isFalse);
    });

    test('week key deterministik dan parser menolak tanggal tidak valid', () {
      expect(
        SundayFajrAttendancePolicy.weekKey(DateTime(2026, 7, 26, 23, 40)),
        '2026-07-26',
      );
      expect(
        SundayFajrAttendancePolicy.tryParseWeekKey('2024-02-29'),
        DateTime.utc(2024, 2, 29),
      );
      expect(SundayFajrAttendancePolicy.tryParseWeekKey('2026-02-29'), isNull);
      expect(SundayFajrAttendancePolicy.tryParseWeekKey('26-07-2026'), isNull);
    });
  });

  group('Sunday Fajr eligibility', () {
    test('menerima santri aktif putra kelas non-Tahsin', () {
      expect(
        isSundayFajrEligible(isActive: true, gender: ' l ', kelas: 'Tahfiz 1'),
        isTrue,
      );
    });

    test('menolak santri nonaktif, putri, Tahsin, dan kelas kosong', () {
      expect(
        isSundayFajrEligible(isActive: false, gender: 'L', kelas: 'Tahfiz 1'),
        isFalse,
      );
      expect(
        isSundayFajrEligible(isActive: true, gender: 'P', kelas: 'Tahfiz 1'),
        isFalse,
      );
      expect(
        isSundayFajrEligible(
          isActive: true,
          gender: 'L',
          kelas: '  Tahsin Akhir ',
        ),
        isFalse,
      );
      expect(
        isSundayFajrEligible(isActive: true, gender: 'L', kelas: ' '),
        isFalse,
      );
    });
  });
}
