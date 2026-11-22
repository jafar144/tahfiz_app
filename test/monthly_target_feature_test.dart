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

    test('penalty decision and excuse round-trip for not achieved', () {
      final model = _report(
        id: 'aug',
        bulan: 8,
        evaluation: MonthlyTargetEvaluation(
          sourceReportId: 'july',
          targetBulan: 8,
          targetTahun: 2026,
          result: MonthlyTargetResult.notAchieved,
          evaluatedAt: DateTime(2026, 8, 29),
          penalty: MonthlyPenaltyDecision.excused,
          penaltyExcuse: 'Sakit dua pekan',
        ),
      );

      final map = model.toFirestore();
      final stored = map['target_evaluation'] as Map<String, dynamic>;
      expect(stored['penalty'], 'excused');
      expect(stored['penalty_excuse'], 'Sakit dua pekan');

      final parsed = MonthlyReportModel.fromMap(id: model.id, data: map);
      expect(parsed.targetEvaluation?.penalty, MonthlyPenaltyDecision.excused);
      expect(parsed.targetEvaluation?.penaltyExcuse, 'Sakit dua pekan');
      expect(parsed.targetEvaluation?.isExcused, isTrue);
      expect(parsed.targetEvaluation?.isPenalized, isFalse);
    });

    test('penalty fields are not stored when target is achieved', () {
      final map = targetEvaluationToMap(
        MonthlyTargetEvaluation(
          sourceReportId: 'july',
          targetBulan: 8,
          targetTahun: 2026,
          result: MonthlyTargetResult.minimumAchieved,
          evaluatedAt: DateTime(2026, 8, 29),
          penalty: MonthlyPenaltyDecision.excused,
          penaltyExcuse: 'Tidak relevan',
        ),
      );

      expect(map.containsKey('penalty'), isFalse);
      expect(map.containsKey('penalty_excuse'), isFalse);
    });

    test('legacy not achieved without decision counts as penalized', () {
      final parsed = MonthlyReportModel.fromMap(
        id: 'legacy',
        data: {
          ..._report(id: 'legacy', bulan: 8).toFirestore(),
          'target_evaluation': {
            'source_report_id': 'july',
            'target_bulan': 8,
            'target_tahun': 2026,
            'result': 'notAchieved',
            'evaluated_at': Timestamp.fromDate(DateTime(2026, 8, 29)),
          },
        },
      );

      expect(
        parsed.targetEvaluation?.penalty,
        MonthlyPenaltyDecision.undecided,
      );
      expect(parsed.targetEvaluation?.isPenalized, isTrue);
    });

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

    test('not achieved requires a penalty decision and an excuse', () async {
      final repository = _FakeMonthlyReportRepository([_juneWithTarget()]);
      final cubit = MonthlyReportInputCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.loadExisting('student-1', 7, 2026);

      Future<void> save({
        MonthlyPenaltyDecision penalty = MonthlyPenaltyDecision.undecided,
        String excuse = '',
      }) => cubit.saveReport(
        asatidzId: 'teacher-1',
        asatidzName: 'Ahmad',
        santriId: 'student-1',
        santriName: 'Ali',
        bulan: 7,
        tahun: 2026,
        hafalanTerakhir: 'An-Naba',
        nilaiPerkembangan: 3,
        nilaiAkhlaq: 4,
        targetMinimum: 'Minimum baru',
        targetOptimum: 'Optimum baru',
        targetResult: MonthlyTargetResult.notAchieved,
        penalty: penalty,
        penaltyExcuse: excuse,
      );

      await save();
      expect(repository.saved, isNull);

      await save(penalty: MonthlyPenaltyDecision.excused, excuse: '  ');
      expect(repository.saved, isNull);
      expect(cubit.state, isA<MonthlyReportInputReady>());

      await save(
        penalty: MonthlyPenaltyDecision.excused,
        excuse: ' Sakit dua pekan ',
      );
      final evaluation = repository.saved!.targetEvaluation!;
      expect(evaluation.penalty, MonthlyPenaltyDecision.excused);
      expect(evaluation.penaltyExcuse, 'Sakit dua pekan');
    });

    test('achieved target drops any penalty decision', () async {
      final repository = _FakeMonthlyReportRepository([_juneWithTarget()]);
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
        hafalanTerakhir: 'An-Naba',
        nilaiPerkembangan: 4,
        nilaiAkhlaq: 4,
        targetMinimum: 'Minimum baru',
        targetOptimum: 'Optimum baru',
        targetResult: MonthlyTargetResult.minimumAchieved,
        penalty: MonthlyPenaltyDecision.excused,
        penaltyExcuse: 'Sisa pilihan lama',
      );

      final evaluation = repository.saved!.targetEvaluation!;
      expect(evaluation.penalty, MonthlyPenaltyDecision.undecided);
      expect(evaluation.penaltyExcuse, isEmpty);
    });

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
    testWidgets('shows a short note when there is no target to evaluate', (
      tester,
    ) async {
      final repository = _FakeMonthlyReportRepository(const []);
      final cubit = MonthlyReportInputCubit(repository: repository);
      addTearDown(cubit.close);

      await _pumpInputPage(tester, cubit);
      await cubit.loadExisting('student-1', 7, 2026);
      await tester.pump();

      expect(find.text('Target Juli 2026'), findsOneWidget);
      expect(find.text('Belum ada target untuk bulan ini.'), findsOneWidget);
      expect(find.text('Target Agustus 2026'), findsOneWidget);
      expect(find.byKey(const Key('target_result_notAchieved')), findsNothing);
    });

    testWidgets('penalty question appears only for not achieved', (
      tester,
    ) async {
      final cubit = MonthlyReportInputCubit(
        repository: _FakeMonthlyReportRepository([_juneWithTarget()]),
      );
      addTearDown(cubit.close);

      await _pumpInputPage(tester, cubit);
      await cubit.loadExisting('student-1', 7, 2026);
      await tester.pumpAndSettle();

      expect(find.text('Murojaah 3 halaman'), findsOneWidget);
      expect(find.text('Masukkan ke daftar hukuman?'), findsNothing);

      await tester.tap(find.byKey(const Key('target_result_notAchieved')));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan ke daftar hukuman?'), findsOneWidget);
      expect(find.byKey(const Key('penalty_excuse_field')), findsNothing);

      await tester.tap(find.byKey(const Key('penalty_excused')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('penalty_excuse_field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('target_result_minimumAchieved')));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan ke daftar hukuman?'), findsNothing);
    });

    testWidgets('save shows inline errors and does not submit', (tester) async {
      final repository = _FakeMonthlyReportRepository([_juneWithTarget()]);
      final cubit = MonthlyReportInputCubit(repository: repository);
      addTearDown(cubit.close);

      await _pumpInputPage(tester, cubit);
      await cubit.loadExisting('student-1', 7, 2026);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('target_result_notAchieved')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('monthly_report_save')));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Ya atau Tidak'), findsOneWidget);
      expect(find.text('Pilih nilai'), findsNWidgets(2));
      expect(repository.saved, isNull);
    });

    testWidgets('fills the form and saves an excused not-achieved result', (
      tester,
    ) async {
      final repository = _FakeMonthlyReportRepository([_juneWithTarget()]);
      final cubit = MonthlyReportInputCubit(repository: repository);
      addTearDown(cubit.close);

      await _pumpInputPage(tester, cubit, withNavigator: true);
      await cubit.loadExisting('student-1', 7, 2026);
      await tester.pumpAndSettle();

      Future<void> tapKey(String key) async {
        final finder = find.byKey(Key(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String hint, String text) async {
        final finder = find.widgetWithText(TextFormField, hint);
        await tester.ensureVisible(finder);
        await tester.enterText(finder, text);
      }

      await tapKey('target_result_notAchieved');
      await tapKey('penalty_excused');
      await enter('Contoh: sakit dua pekan', 'Sakit tifus');
      await enter('Contoh: Al-Baqarah ayat 1-20', 'An-Naba ayat 1-30');
      await tapKey('score_perkembangan_3');
      await tapKey('score_akhlaq_5');
      await enter(
        'Contoh: Murojaah 3 halaman dengan lancar',
        'Murojaah 2 halaman',
      );
      await enter(
        'Contoh: Menambah hafalan 5 halaman dengan lancar',
        'Hafalan 4 halaman',
      );
      await tapKey('monthly_report_save');

      final saved = repository.saved!;
      expect(saved.hafalanTerakhir, 'An-Naba ayat 1-30');
      expect(saved.nilaiPerkembangan, 3);
      expect(saved.nilaiAkhlaq, 5);
      expect(saved.target?.minimum, 'Murojaah 2 halaman');
      expect(saved.targetEvaluation?.result, MonthlyTargetResult.notAchieved);
      expect(saved.targetEvaluation?.penalty, MonthlyPenaltyDecision.excused);
      expect(saved.targetEvaluation?.penaltyExcuse, 'Sakit tifus');
    });

    testWidgets('edit restores the saved penalty decision and excuse', (
      tester,
    ) async {
      final existing = _report(
        id: 'july',
        bulan: 7,
        target: const MonthlyTarget(
          bulan: 8,
          tahun: 2026,
          minimum: 'Minimum Agustus',
          optimum: 'Optimum Agustus',
        ),
        evaluation: MonthlyTargetEvaluation(
          sourceReportId: 'june',
          targetBulan: 7,
          targetTahun: 2026,
          result: MonthlyTargetResult.notAchieved,
          evaluatedAt: DateTime(2026, 7, 28),
          penalty: MonthlyPenaltyDecision.excused,
          penaltyExcuse: 'Pulang kampung',
        ),
      );
      final cubit = MonthlyReportInputCubit(
        repository: _FakeMonthlyReportRepository([existing, _juneWithTarget()]),
      );
      addTearDown(cubit.close);

      await _pumpInputPage(tester, cubit);
      await cubit.loadExisting('student-1', 7, 2026);
      await tester.pumpAndSettle();

      expect(find.text('Masukkan ke daftar hukuman?'), findsOneWidget);
      expect(find.text('Pulang kampung'), findsOneWidget);
      expect(find.text('Perbarui penilaian'), findsOneWidget);
    });
  });
}

MonthlyReportModel _juneWithTarget() => _report(
  id: 'june',
  bulan: 6,
  target: const MonthlyTarget(
    bulan: 7,
    tahun: 2026,
    minimum: 'Murojaah 3 halaman',
    optimum: 'Hafalan 5 halaman',
  ),
);

Future<void> _pumpInputPage(
  WidgetTester tester,
  MonthlyReportInputCubit cubit, {
  bool withNavigator = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = BlocProvider.value(
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
  );
  if (!withNavigator) {
    await tester.pumpWidget(MaterialApp(home: page));
    return;
  }
  // Halaman memanggil Navigator.pop setelah tersimpan, jadi perlu rute di bawahnya.
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => page)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
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
  Future<Either<Failure, List<MonthlyReport>>> getReportsByPeriod(
    int bulan,
    int tahun,
  ) async {
    return Right(
      reports
          .where((report) => report.bulan == bulan && report.tahun == tahun)
          .toList(),
    );
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
