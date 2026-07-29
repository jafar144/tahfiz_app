import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/pages/sunday_fajr_admin_page.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/pages/sunday_fajr_editor_page.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/widgets/sunday_fajr_santri_preview.dart';

import 'helpers/sunday_fajr_fake_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('preview santri menampilkan status dan alasan izin', (
    tester,
  ) async {
    final repository = SundayFajrFakeRepository()
      ..santriHistory = [
        SundayFajrParticipant(
          id: 'santri-1',
          santriId: 'santri-1',
          santriName: 'Ahmad',
          santriNis: '101',
          kelas: 'Tahfiz 1',
          weekKey: '2026-07-26',
          eventDate: DateTime.utc(2026, 7, 26),
          status: SundayFajrAttendanceStatus.izin,
          izinReason: 'Sakit dan beristirahat',
          createdAt: DateTime.utc(2026, 7, 26),
          updatedAt: DateTime.utc(2026, 7, 26),
        ),
      ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SundayFajrSantriPreview(
            repository: repository,
            santriId: 'santri-1',
            isEligible: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kehadiran Minggu Subuh'), findsOneWidget);
    expect(find.text('Izin'), findsOneWidget);
    expect(find.text('Alasan: Sakit dan beristirahat'), findsOneWidget);
    expect(find.text('Lihat seluruh riwayat'), findsOneWidget);
  });

  testWidgets('preview tidak dirender untuk santri yang tidak wajib', (
    tester,
  ) async {
    final repository = SundayFajrFakeRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SundayFajrSantriPreview(
            repository: repository,
            santriId: 'santri-1',
            isEligible: false,
          ),
        ),
      ),
    );

    expect(find.text('Kehadiran Minggu Subuh'), findsNothing);
  });

  testWidgets(
    'santri yang tidak lagi wajib tetap dapat melihat riwayat lamanya',
    (tester) async {
      final repository = SundayFajrFakeRepository()
        ..santriHistory = [
          SundayFajrParticipant(
            id: 'santri-1',
            santriId: 'santri-1',
            santriName: 'Ahmad',
            santriNis: '101',
            kelas: 'Tahfiz 1',
            weekKey: '2026-07-26',
            eventDate: DateTime.utc(2026, 7, 26),
            status: SundayFajrAttendanceStatus.hadir,
            createdAt: DateTime.utc(2026, 7, 26),
            updatedAt: DateTime.utc(2026, 7, 26),
          ),
        ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SundayFajrSantriPreview(
              repository: repository,
              santriId: 'santri-1',
              isEligible: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kehadiran Minggu Subuh'), findsOneWidget);
      expect(find.text('Hadir'), findsOneWidget);
    },
  );

  testWidgets(
    'editor mengaktifkan simpan setelah semua peserta diberi status',
    (tester) async {
      final repository = SundayFajrFakeRepository()
        ..eligibleSantri = [
          sundayFajrTestSantri(id: 's1', name: 'Ahmad', nis: '101'),
          sundayFajrTestSantri(id: 's2', name: 'Bilal', nis: '102'),
        ];
      final latestSunday = SundayFajrAttendancePolicy.latestSunday();

      await tester.pumpWidget(
        MaterialApp(
          home: SundayFajrEditorPage(
            repository: repository,
            actorId: 'admin-1',
            eventDate: latestSunday,
            now: latestSunday.add(const Duration(hours: 5)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveFinder = find.widgetWithText(ElevatedButton, 'Simpan Absensi');
      expect(saveFinder, findsOneWidget);
      expect(tester.widget<ElevatedButton>(saveFinder).onPressed, isNull);

      await tester.tap(find.text('Semua Hadir'));
      await tester.pump();

      expect(tester.widget<ElevatedButton>(saveFinder).onPressed, isNotNull);
      expect(find.text('Hadir (2)'), findsOneWidget);
    },
  );

  testWidgets('hari Senin tidak menawarkan pembuatan data baru', (
    tester,
  ) async {
    final repository = SundayFajrFakeRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SundayFajrAdminPage(
          repository: repository,
          adminId: 'admin-1',
          now: DateTime.utc(2026, 7, 27, 5),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kelola Absensi'));
    await tester.pumpAndSettle();

    expect(find.text('Buat'), findsNothing);
    expect(find.text('Belum tersedia'), findsNWidgets(2));
  });

  testWidgets('konflik revisi menyediakan aksi Muat ulang', (tester) async {
    final repository = SundayFajrFakeRepository()
      ..eligibleSantri = [sundayFajrTestSantri(id: 's1', name: 'Ahmad')]
      ..saveError = const SundayFajrRevisionConflictException();
    final sunday = DateTime.utc(2026, 7, 26);

    await tester.pumpWidget(
      MaterialApp(
        home: SundayFajrEditorPage(
          repository: repository,
          actorId: 'admin-1',
          eventDate: sunday,
          now: sunday.add(const Duration(hours: 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua Hadir'));
    await tester.pump();
    await tester.tap(find.text('Simpan Absensi'));
    await tester.pumpAndSettle();

    expect(find.text('Muat ulang'), findsOneWidget);
    expect(find.textContaining('diperbarui admin lain'), findsOneWidget);
  });
}
