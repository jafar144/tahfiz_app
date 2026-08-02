import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_report_detail_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_report_detail_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/santri_report_detail_page.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';

void main() {
  group('MonthlyTargetProgress', () {
    test('pairs a period with the prior report target and its evaluation', () {
      final july = _report(
        id: 'july',
        bulan: 7,
        tahun: 2026,
        target: const MonthlyTarget(
          bulan: 8,
          tahun: 2026,
          minimum: 'Murojaah empat halaman',
          optimum: 'Menambah enam halaman',
        ),
      );
      final august = _report(
        id: 'august',
        bulan: 8,
        tahun: 2026,
        target: const MonthlyTarget(
          bulan: 9,
          tahun: 2026,
          minimum: 'Target September minimum',
          optimum: 'Target September optimum',
        ),
        evaluation: MonthlyTargetEvaluation(
          sourceReportId: july.id,
          targetBulan: 8,
          targetTahun: 2026,
          result: MonthlyTargetResult.minimumAchieved,
          evaluatedAt: DateTime(2026, 8, 28),
        ),
      );

      final progress = MonthlyTargetProgress.forAssessment(august, [
        august,
        july,
      ]);

      expect(progress?.sourceReportId, july.id);
      expect(progress?.target.bulan, 8);
      expect(progress?.target.minimum, 'Murojaah empat halaman');
      expect(progress?.result, MonthlyTargetResult.minimumAchieved);
    });

    test('keeps an unevaluated current target visible', () {
      final now = DateTime.now();
      final previous = DateTime(now.year, now.month - 1);
      final source = _report(
        id: 'source',
        bulan: previous.month,
        tahun: previous.year,
        target: MonthlyTarget(
          bulan: now.month,
          tahun: now.year,
          minimum: 'Minimum bulan ini',
          optimum: 'Optimum bulan ini',
        ),
      );

      final progress = MonthlyTargetProgress.forPeriod(
        [source],
        bulan: now.month,
        tahun: now.year,
      );

      expect(progress?.target.minimum, 'Minimum bulan ini');
      expect(progress?.result, MonthlyTargetResult.notAssessed);
    });
  });

  testWidgets('report card shows the period target and achievement result', (
    tester,
  ) async {
    final report = _report(id: 'august', bulan: 8, tahun: 2026);
    const progress = MonthlyTargetProgress(
      sourceReportId: 'july',
      target: MonthlyTarget(
        bulan: 8,
        tahun: 2026,
        minimum: 'Murojaah empat halaman',
        optimum: 'Menambah enam halaman',
      ),
      result: MonthlyTargetResult.minimumAchieved,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MonthlyReportCard(report: report, periodTarget: progress),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('monthly-report-target-section')),
      findsOneWidget,
    );
    expect(find.text('Target Agustus 2026'), findsOneWidget);
    expect(find.text('Murojaah empat halaman'), findsOneWidget);
    expect(find.text('Menambah enam halaman'), findsOneWidget);
    expect(find.text('Minimum tercapai'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('monthly-target-minimum')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('monthly-target-optimum')),
        matching: find.byIcon(Icons.circle_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('report card labels an unmet period target clearly', (
    tester,
  ) async {
    final report = _report(id: 'august', bulan: 8, tahun: 2026);
    const progress = MonthlyTargetProgress(
      sourceReportId: 'july',
      target: MonthlyTarget(
        bulan: 8,
        tahun: 2026,
        minimum: 'Minimum belum selesai',
        optimum: 'Optimum belum selesai',
      ),
      result: MonthlyTargetResult.notAchieved,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlyReportCard(report: report, periodTarget: progress),
        ),
      ),
    );

    expect(find.text('Belum tercapai'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('monthly-report-target-section')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'current target card shows minimum and optimum below the header',
    (tester) async {
      const progress = MonthlyTargetProgress(
        sourceReportId: 'previous',
        target: MonthlyTarget(
          bulan: 8,
          tahun: 2026,
          minimum: 'Minimum yang diisi asatidz',
          optimum: 'Optimum yang diisi asatidz',
        ),
        result: MonthlyTargetResult.notAssessed,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: CurrentMonthlyTargetCard(progress: progress),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('current-month-target-card')),
        findsOneWidget,
      );
      expect(find.text('Minimum yang diisi asatidz'), findsOneWidget);
      expect(find.text('Optimum yang diisi asatidz'), findsOneWidget);
    },
  );

  testWidgets(
    'santri card scrolls away while the current target stays pinned',
    (tester) async {
      final now = DateTime.now();
      final previous = DateTime(now.year, now.month - 1);
      final reports = <MonthlyReport>[
        _report(
          id: 'target-source',
          bulan: previous.month,
          tahun: previous.year,
          target: MonthlyTarget(
            bulan: now.month,
            tahun: now.year,
            minimum: 'Minimum bulan berjalan',
            optimum: 'Optimum bulan berjalan',
          ),
        ),
        for (var index = 1; index < 10; index++)
          _report(
            id: 'history-$index',
            bulan: DateTime(now.year, now.month - index - 1).month,
            tahun: DateTime(now.year, now.month - index - 1).year,
          ),
      ];

      getIt.pushNewScope();
      getIt.registerSingleton<MonthlyReportRepository>(
        _FakeMonthlyReportRepository(reports),
      );
      addTearDown(getIt.popScope);

      final santri = SantriEntity(
        id: 'student-1',
        name: 'Muhammad Wildan Syahab',
        nis: '20260001',
        kelas: 'Tahfiz A',
        jenisKelamin: 'L',
        isActive: true,
        isFree: false,
        tanggalMasuk: DateTime(now.year, now.month),
        pembimbing: 'Ustadz Ahmad',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SantriReportDetailPage(santri: santri, viewOnly: true),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = find.byType(CustomScrollView);
      final santriCard = find.byType(SantriCard);
      final targetCard = find.byKey(const Key('current-month-target-card'));

      expect(santriCard.hitTestable(), findsOneWidget);
      expect(targetCard.hitTestable(), findsOneWidget);

      await tester.drag(scrollView, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(santriCard.hitTestable(), findsNothing);
      expect(targetCard.hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(targetCard).dy,
        closeTo(tester.getTopLeft(scrollView).dy, 2),
      );
    },
  );

  test(
    'detail cubit exposes the current target and paginated target map',
    () async {
      final now = DateTime.now();
      final previous = DateTime(now.year, now.month - 1);
      final source = _report(
        id: 'previous-report',
        bulan: previous.month,
        tahun: previous.year,
        target: MonthlyTarget(
          bulan: now.month,
          tahun: now.year,
          minimum: 'Minimum aktif',
          optimum: 'Optimum aktif',
        ),
      );
      final assessment = _report(
        id: 'current-report',
        bulan: now.month,
        tahun: now.year,
        evaluation: MonthlyTargetEvaluation(
          sourceReportId: source.id,
          targetBulan: now.month,
          targetTahun: now.year,
          result: MonthlyTargetResult.optimumAchieved,
          evaluatedAt: now,
        ),
      );
      final cubit = SantriReportDetailCubit(
        repository: _FakeMonthlyReportRepository([assessment, source]),
      );
      addTearDown(cubit.close);

      await cubit.load('student-1', joinedAt: previous);

      final state = cubit.state as SantriReportDetailLoaded;
      expect(state.currentMonthTarget?.target.minimum, 'Minimum aktif');
      expect(
        state.periodTargetsByReportId[assessment.id]?.result,
        MonthlyTargetResult.optimumAchieved,
      );
    },
  );
}

MonthlyReport _report({
  required String id,
  required int bulan,
  required int tahun,
  MonthlyTarget? target,
  MonthlyTargetEvaluation? evaluation,
}) {
  return MonthlyReport(
    id: id,
    asatidzId: 'teacher-1',
    asatidzName: 'Ahmad',
    santriId: 'student-1',
    santriName: 'Ali',
    bulan: bulan,
    tahun: tahun,
    hafalanTerakhir: 'An-Naba',
    nilaiPerkembangan: 4,
    nilaiAkhlaq: 5,
    target: target,
    targetEvaluation: evaluation,
    createdAt: DateTime(tahun, bulan, 28),
    updatedAt: DateTime(tahun, bulan, 28),
  );
}

class _FakeMonthlyReportRepository implements MonthlyReportRepository {
  final List<MonthlyReport> reports;

  const _FakeMonthlyReportRepository(this.reports);

  @override
  Future<Either<Failure, MonthlyReport>> createOrUpdateReport(
    MonthlyReport report,
  ) async => Right(report);

  @override
  Future<Either<Failure, MonthlyReport?>> getLatestReportBySantri(
    String santriId,
  ) async => Right(reports.isEmpty ? null : reports.first);

  @override
  Future<Either<Failure, MonthlyReport?>> getReport(
    String santriId,
    int bulan,
    int tahun,
  ) async => const Right(null);

  @override
  Future<Either<Failure, Set<String>>> getReportedSantriIds(
    int bulan,
    int tahun,
  ) async => const Right({});

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  ) async => Right(reports);

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  }) async => Right(reports);
}
