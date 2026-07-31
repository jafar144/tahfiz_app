import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/data/models/monthly_report_model.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/monthly_report_input_page.dart';

void main() {
  group('monthly target persistence', () {
    test('legacy report without target remains readable', () {
      final model = MonthlyReportModel.fromMap(
        id: 'legacy',
        data: {
          'asatidz_id': 'teacher-1',
          'asatidz_name': 'Ahmad',
          'santri_id': 'student-1',
          'santri_name': 'Ali',
          'bulan': 6,
          'tahun': 2026,
          'hafalan_terakhir': 'An-Naba ayat 1-20',
          'nilai_perkembangan': 4,
          'nilai_akhlaq': 5,
          'created_at': Timestamp.fromDate(DateTime(2026, 6, 28)),
          'updated_at': Timestamp.fromDate(DateTime(2026, 6, 28)),
        },
      );

      expect(model.target, isNull);
      expect(model.targetEvaluation, isNull);
      expect(model.nilaiPerkembangan, 4);
    });

    test(
      'target and four-state evaluation round-trip through Firestore map',
      () {
        final model = _report(
          id: 'july',
          bulan: 7,
          target: const MonthlyTarget(
            bulan: 8,
            tahun: 2026,
            minimum: 'Murojaah 3 halaman',
            optimum: 'Menambah hafalan 5 halaman',
          ),
          evaluation: MonthlyTargetEvaluation(
            sourceReportId: 'june',
            targetBulan: 7,
            targetTahun: 2026,
            result: MonthlyTargetResult.optimumAchieved,
            evaluatedAt: DateTime(2026, 7, 29),
          ),
        );

        final map = model.toFirestore();
        final parsed = MonthlyReportModel.fromMap(id: model.id, data: map);

        expect(parsed.target?.bulan, 8);
        expect(parsed.target?.minimum, 'Murojaah 3 halaman');
        expect(
          parsed.targetEvaluation?.result,
          MonthlyTargetResult.optimumAchieved,
        );
        expect(parsed.targetEvaluation?.sourceReportId, 'june');
        expect(
          (map['target_evaluation'] as Map<String, dynamic>)['result'],
          'optimumAchieved',
        );
      },
    );

    test('unknown stored result safely falls back to not assessed', () {
      expect(
        MonthlyTargetResult.fromStorage('future_value'),
        MonthlyTargetResult.notAssessed,
      );
      expect(
        MonthlyTargetResult.fromStorage('minimum_achieved'),
        MonthlyTargetResult.minimumAchieved,
      );
    });
  });

  group('monthly assessment flow', () {
    test(
      'evaluates current target and creates target for next month',
      () async {
        final june = _report(
          id: 'june',
          bulan: 6,
          target: const MonthlyTarget(
            bulan: 7,
            tahun: 2026,
            minimum: 'Murojaah 3 halaman',
            optimum: 'Hafalan 5 halaman',
          ),
        );
        final repository = _FakeMonthlyReportRepository([june]);
        final cubit = MonthlyReportInputCubit(repository: repository);
        addTearDown(cubit.close);

        await cubit.loadExisting('student-1', 7, 2026);
        final ready = cubit.state as MonthlyReportInputReady;
        expect(ready.targetToEvaluate?.id, 'june');

        await cubit.saveReport(
          asatidzId: 'teacher-1',
          asatidzName: 'Ahmad',
          santriId: 'student-1',
          santriName: 'Ali',
          bulan: 7,
          tahun: 2026,
          hafalanTerakhir: 'An-Naba selesai',
          nilaiPerkembangan: 4,
          nilaiAkhlaq: 5,
          targetMinimum: 'Murojaah 4 halaman',
          targetOptimum: 'Hafalan 6 halaman',
          targetResult: MonthlyTargetResult.minimumAchieved,
        );

        final saved = repository.saved!;
        expect(saved.target?.bulan, 8);
        expect(saved.target?.tahun, 2026);
        expect(saved.targetEvaluation?.sourceReportId, 'june');
        expect(
          saved.targetEvaluation?.result,
          MonthlyTargetResult.minimumAchieved,
        );
        expect(cubit.state, isA<MonthlyReportInputSuccess>());
      },
    );

    test(
      'requires target evaluation when a target exists for this month',
      () async {
        final repository = _FakeMonthlyReportRepository([
          _report(
            id: 'june',
            bulan: 6,
            target: const MonthlyTarget(
              bulan: 7,
              tahun: 2026,
              minimum: 'Minimum',
              optimum: 'Optimum',
            ),
          ),
        ]);
        final cubit = MonthlyReportInputCubit(repository: repository);
        addTearDown(cubit.close);
        await cubit.loadExisting('student-1', 7, 2026);

        await cubit.saveReport(
          asatidzId: 'teacher-1',
          asatidzName: 'Ahmad',
          santriId: 'student-1',
          santriName: 'Ali',
          bulan: 7,
          tahun: 2026,
          hafalanTerakhir: 'An-Naba selesai',
          nilaiPerkembangan: 4,
          nilaiAkhlaq: 5,
          targetMinimum: 'Minimum baru',
          targetOptimum: 'Optimum baru',
        );

        expect(repository.saved, isNull);
        expect(cubit.state, isA<MonthlyReportInputReady>());
      },
    );

    test('rejects blank next-month targets outside the UI layer', () async {
      final repository = _FakeMonthlyReportRepository(const []);
      final cubit = MonthlyReportInputCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.loadExisting('student-1', 7, 2026);

      await cubit.saveReport(
        asatidzId: 'teacher-1',
        asatidzName: 'Ahmad',
        santriId: 'student-1',
        santriName: 'Ali',
        bulan: 7,
        tahun: 2026,
        hafalanTerakhir: 'An-Naba selesai',
        nilaiPerkembangan: 4,
        nilaiAkhlaq: 5,
        targetMinimum: '   ',
        targetOptimum: 'Optimum baru',
      );

      expect(repository.saved, isNull);
      expect(cubit.state, isA<MonthlyReportInputReady>());
    });
  });

  group('monthly target input UI', () {
    testWidgets(
      'keeps evaluation section visible when previous target is unavailable',
      (tester) async {
        final repository = _FakeMonthlyReportRepository(const []);
        final cubit = MonthlyReportInputCubit(repository: repository);
        addTearDown(cubit.close);

        await _pumpInputPage(tester, cubit);
        await cubit.loadExisting('student-1', 7, 2026);
        await tester.pump();

        expect(find.text('Evaluasi Target Bulan Ini'), findsOneWidget);
        expect(find.text('Belum ada target bulan sebelumnya'), findsOneWidget);
        expect(find.textContaining('Target untuk Juli 2026'), findsOneWidget);
      },
    );

    testWidgets('shows result choices when previous target exists', (
      tester,
    ) async {
      final repository = _FakeMonthlyReportRepository([
        _report(
          id: 'june',
          bulan: 6,
          target: const MonthlyTarget(
            bulan: 7,
            tahun: 2026,
            minimum: 'Murojaah 3 halaman',
            optimum: 'Hafalan 5 halaman',
          ),
        ),
      ]);
      final cubit = MonthlyReportInputCubit(repository: repository);
      addTearDown(cubit.close);

      await _pumpInputPage(tester, cubit);
      await cubit.loadExisting('student-1', 7, 2026);
      await tester.pump();

      expect(find.text('Belum ada target bulan sebelumnya'), findsNothing);
      expect(find.text('Belum tercapai'), findsOneWidget);
      expect(find.text('Minimum tercapai'), findsOneWidget);
      expect(find.text('Optimum tercapai'), findsOneWidget);
    });
  });
}

Future<void> _pumpInputPage(
  WidgetTester tester,
  MonthlyReportInputCubit cubit,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: MonthlyReportInputPage(
          santri: SantriEntity(
            id: 'student-1',
            name: 'Ali',
            nis: '4110',
            kelas: 'Tahfizh',
            jenisKelamin: 'L',
            isActive: true,
            isFree: false,
          ),
          asatidzId: 'teacher-1',
          asatidzName: 'Ahmad',
          bulan: 7,
          tahun: 2026,
        ),
      ),
    ),
  );
}

MonthlyReportModel _report({
  required String id,
  required int bulan,
  MonthlyTarget? target,
  MonthlyTargetEvaluation? evaluation,
}) {
  return MonthlyReportModel(
    id: id,
    asatidzId: 'teacher-1',
    asatidzName: 'Ahmad',
    santriId: 'student-1',
    santriName: 'Ali',
    bulan: bulan,
    tahun: 2026,
    hafalanTerakhir: 'An-Naba',
    nilaiPerkembangan: 4,
    nilaiAkhlaq: 5,
    target: target,
    targetEvaluation: evaluation,
    createdAt: DateTime(2026, bulan, 28),
    updatedAt: DateTime(2026, bulan, 28),
  );
}

class _FakeMonthlyReportRepository implements MonthlyReportRepository {
  final List<MonthlyReport> reports;
  MonthlyReport? saved;

  _FakeMonthlyReportRepository(this.reports);

  @override
  Future<Either<Failure, MonthlyReport>> createOrUpdateReport(
    MonthlyReport report,
  ) async {
    saved = report;
    return Right(report);
  }

  @override
  Future<Either<Failure, MonthlyReport?>> getLatestReportBySantri(
    String santriId,
  ) async {
    return Right(reports.isEmpty ? null : reports.first);
  }

  @override
  Future<Either<Failure, MonthlyReport?>> getReport(
    String santriId,
    int bulan,
    int tahun,
  ) async {
    for (final report in reports) {
      if (report.santriId == santriId &&
          report.bulan == bulan &&
          report.tahun == tahun) {
        return Right(report);
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, Set<String>>> getReportedSantriIds(
    int bulan,
    int tahun,
  ) async {
    return const Right({});
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  ) async {
    return Right(reports);
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  }) async {
    return Right(reports);
  }
}
