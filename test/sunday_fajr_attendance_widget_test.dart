import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
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

  testWidgets('preview santri menampilkan kalender mulai Agustus 2026', (
    tester,
  ) async {
    final repository = SundayFajrFakeRepository()
      ..santriHistory = [
        _participant(
          id: 'santri-1',
          name: 'Ahmad',
          eventDate: DateTime(2026, 8, 2),
          status: SundayFajrAttendanceStatus.izin,
          izinReason: 'Urusan keluarga',
        ),
      ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SundayFajrSantriPreview(
            repository: repository,
            santriId: 'santri-1',
            isEligible: true,
            now: DateTime(2026, 8, 30),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Absensi Minggu Subuh'), findsOneWidget);
    expect(find.text('Agustus 2026'), findsOneWidget);
    expect(find.text('Izin'), findsWidgets);
    expect(find.textContaining('Urusan keluarga'), findsNothing);
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
            now: DateTime(2026, 8, 30),
          ),
        ),
      ),
    );

    expect(find.text('Absensi Minggu Subuh'), findsNothing);
  });

  testWidgets(
    'editor memakai input satu per satu tanpa alasan izin dan Semua Hadir',
    (tester) async {
      _useTallTestSurface(tester);
      final repository = SundayFajrFakeRepository()
        ..eligibleSantri = [
          sundayFajrTestSantri(id: 's1', name: 'Ahmad', nis: '101'),
          sundayFajrTestSantri(id: 's2', name: 'Bilal', nis: '102'),
        ];
      final sunday = DateTime.utc(2026, 8, 2);

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

      final saveFinder = find.widgetWithText(ElevatedButton, 'Simpan Absensi');
      expect(find.byType(AiwaSearch), findsOneWidget);
      expect(
        find.byKey(const Key('sunday-fajr-attendance-chart')),
        findsOneWidget,
      );
      expect(find.text('Semua Hadir'), findsNothing);
      expect(find.text('Tulis alasan izin'), findsNothing);
      expect(tester.widget<ElevatedButton>(saveFinder).onPressed, isNull);

      await tester.tap(find.byKey(const Key('s1-status-izin')));
      await tester.pump();
      expect(tester.widget<ElevatedButton>(saveFinder).onPressed, isNull);

      await tester.tap(find.byKey(const Key('s2-status-hadir')));
      await tester.pump();

      expect(tester.widget<ElevatedButton>(saveFinder).onPressed, isNotNull);
      expect(find.text('Hadir (1)'), findsOneWidget);
      expect(find.text('Izin (1)'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets('overview ter-scroll dan AiwaSearch tetap pinned', (
    tester,
  ) async {
    final repository = SundayFajrFakeRepository()
      ..eligibleSantri = List.generate(
        12,
        (index) => sundayFajrTestSantri(
          id: 's$index',
          name: 'Santri $index',
          nis: '10$index',
        ),
      );
    final sunday = DateTime.utc(2026, 8, 2);

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

    final scrollView = find.byKey(const Key('sunday-fajr-editor-scroll-view'));
    await tester.drag(scrollView, const Offset(0, -520));
    await tester.pumpAndSettle();

    final pinnedHeader = find.byKey(const Key('sunday-fajr-pinned-search'));
    expect(tester.getTopLeft(pinnedHeader).dy, closeTo(kToolbarHeight, 1));
    expect(find.byType(AiwaSearch).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('sunday-fajr-attendance-chart')).hitTestable(),
      findsNothing,
    );
  });

  testWidgets(
    'record terkunci memakai SantriCard dan filter status di atas list',
    (tester) async {
      _useTallTestSurface(tester);
      final repository = SundayFajrFakeRepository();
      final sunday = DateTime.utc(2026, 8, 2);
      final weekKey = SundayFajrAttendancePolicy.weekKey(sunday);
      repository.attendanceByWeek[weekKey] = sundayFajrTestAttendance(
        eventDate: sunday,
        participantCount: 3,
        totalHadir: 1,
        totalIzin: 1,
        totalAlpha: 1,
      );
      repository.participantsByWeek[weekKey] = [
        _participant(
          id: 's1',
          name: 'Ahmad',
          eventDate: sunday,
          status: SundayFajrAttendanceStatus.hadir,
        ),
        _participant(
          id: 's2',
          name: 'Bilal',
          eventDate: sunday,
          status: SundayFajrAttendanceStatus.izin,
          izinReason: 'Urusan keluarga',
        ),
        _participant(
          id: 's3',
          name: 'Chandra',
          eventDate: sunday,
          status: SundayFajrAttendanceStatus.alpha,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SundayFajrEditorPage(
            repository: repository,
            actorId: 'admin-1',
            eventDate: sunday,
            now: DateTime.utc(2026, 8, 3, 5),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SantriCard), findsNWidgets(3));
      expect(find.byKey(const Key('s1-status-hadir')), findsNothing);
      expect(find.text('Urusan keluarga'), findsNothing);
      expect(find.text('Hadir (1)'), findsOneWidget);
      expect(find.text('Izin (1)'), findsOneWidget);
      expect(find.text('Alpha (1)'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Simpan Perubahan'),
        findsNothing,
      );

      await tester.tap(find.text('Izin (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(SantriCard), findsOneWidget);
      expect(find.text('Bilal'), findsOneWidget);
      expect(find.text('Ahmad'), findsNothing);
      expect(find.text('Chandra'), findsNothing);
    },
  );

  testWidgets('FAB tambah hanya tersedia pada hari Minggu', (tester) async {
    final sundayRepository = SundayFajrFakeRepository();
    final sunday = DateTime.utc(2026, 8, 2, 5);

    await tester.pumpWidget(
      MaterialApp(
        home: SundayFajrAdminPage(
          repository: sundayRepository,
          adminId: 'admin-1',
          now: sunday,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-sunday-fajr-attendance')), findsOneWidget);

    final mondayRepository = SundayFajrFakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SundayFajrAdminPage(
          repository: mondayRepository,
          adminId: 'admin-1',
          now: DateTime.utc(2026, 8, 3, 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-sunday-fajr-attendance')), findsNothing);
    expect(
      find.text('Catatan pertama dapat dibuat pada hari Minggu.'),
      findsOneWidget,
    );
  });

  testWidgets('konflik revisi menyediakan aksi Muat ulang', (tester) async {
    _useTallTestSurface(tester);
    final repository = SundayFajrFakeRepository()
      ..eligibleSantri = [sundayFajrTestSantri(id: 's1', name: 'Ahmad')]
      ..saveError = const SundayFajrRevisionConflictException();
    final sunday = DateTime.utc(2026, 8, 2);

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
    await tester.tap(find.byKey(const Key('s1-status-hadir')));
    await tester.pump();
    await tester.tap(find.text('Simpan Absensi'));
    await tester.pumpAndSettle();

    expect(find.text('Muat ulang'), findsOneWidget);
    expect(find.textContaining('diperbarui admin lain'), findsOneWidget);
  });
}

void _useTallTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

SundayFajrParticipant _participant({
  required String id,
  required String name,
  required DateTime eventDate,
  required SundayFajrAttendanceStatus status,
  String izinReason = '',
}) {
  final weekKey = SundayFajrAttendancePolicy.weekKey(eventDate);
  return SundayFajrParticipant(
    id: id,
    santriId: id,
    santriName: name,
    santriNis: '10$id',
    kelas: 'Tahfiz 1',
    weekKey: weekKey,
    eventDate: eventDate,
    status: status,
    izinReason: izinReason,
    createdAt: eventDate,
    updatedAt: eventDate,
  );
}
