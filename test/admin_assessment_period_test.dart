import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/admin_assessment_page.dart';

void main() {
  late _FakeMonthlyReportRepository reportRepository;
  late _FakeScheduleRepository scheduleRepository;
  late _FakeAsatidzRepository asatidzRepository;
  late AdminAssessmentCubit cubit;

  setUp(() {
    reportRepository = _FakeMonthlyReportRepository(
      {
        (bulan: 1, tahun: 2027): {'santri-lama'},
        (bulan: 12, tahun: 2026): <String>{},
      },
      reportsByPeriod: {
        (bulan: 1, tahun: 2027): [
          _report(
            santriId: 'santri-lama',
            bulan: 1,
            tahun: 2027,
            result: MonthlyTargetResult.minimumAchieved,
          ),
        ],
        (bulan: 12, tahun: 2026): const [],
      },
    );
    scheduleRepository = _FakeScheduleRepository();
    asatidzRepository = _FakeAsatidzRepository();
    cubit = AdminAssessmentCubit(
      scheduleRepository: scheduleRepository,
      reportRepository: reportRepository,
      asatidzRepository: asatidzRepository,
      now: () => DateTime(2027, 1, 15),
    );
    addTearDown(cubit.close);
  });

  test(
    'loads the selected period across a year boundary and respects join month',
    () async {
      expect(cubit.currentPeriod, DateTime(2027, 1));
      expect(cubit.previousPeriod, DateTime(2026, 12));
      expect(cubit.isAvailablePeriod(DateTime(2026, 11)), isFalse);

      await cubit.load();

      final current = cubit.state as AdminAssessmentLoaded;
      expect((current.bulan, current.tahun), (1, 2027));
      expect(current.previousMonthHasIncompleteAssessment, isTrue);
      expect(current.pembimbingList.single.totalSantri, 2);
      expect(current.pembimbingList.single.unassessedSantri.map((s) => s.id), [
        'santri-baru',
      ]);
      expect(reportRepository.requests, [(bulan: 12, tahun: 2026)]);
      expect(reportRepository.reportListRequests, [(bulan: 1, tahun: 2027)]);
      expect(scheduleRepository.bulkRequests, 1);
      expect(scheduleRepository.singleRequests, 0);
      expect(scheduleRepository.hydrateTeacherNamesRequests, [false]);
      expect(asatidzRepository.requests, 1);

      reportRepository.requests.clear();
      reportRepository.reportListRequests.clear();
      await cubit.load(period: DateTime(2026, 12));

      final previous = cubit.state as AdminAssessmentLoaded;
      expect((previous.bulan, previous.tahun), (12, 2026));
      expect(previous.pembimbingList.single.totalSantri, 1);
      expect(previous.pembimbingList.single.unassessedSantri.map((s) => s.id), [
        'santri-lama',
      ]);
      expect(reportRepository.requests, isEmpty);
      expect(reportRepository.reportListRequests, [(bulan: 12, tahun: 2026)]);
      expect(scheduleRepository.bulkRequests, 1);
      expect(asatidzRepository.requests, 1);
    },
  );

  testWidgets(
    'shows only current and previous navigation with incomplete pulse',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const AdminAssessmentPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Januari 2027'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('target_recap_minimum')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Penilaian Bulan Januari'), findsNothing);
      expect(
        find.byKey(const Key('admin_assessment_previous_incomplete_indicator')),
        findsOneWidget,
      );

      var previousButton = tester.widget<IconButton>(
        find.byKey(const Key('admin_assessment_previous_month')),
      );
      var nextButton = tester.widget<IconButton>(
        find.byKey(const Key('admin_assessment_next_month')),
      );
      expect(previousButton.onPressed, isNotNull);
      expect(nextButton.onPressed, isNull);

      await tester.tap(
        find.byKey(const Key('admin_assessment_previous_month')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Desember 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('target_recap_minimum')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('admin_assessment_previous_incomplete_indicator')),
        findsNothing,
      );
      previousButton = tester.widget<IconButton>(
        find.byKey(const Key('admin_assessment_previous_month')),
      );
      nextButton = tester.widget<IconButton>(
        find.byKey(const Key('admin_assessment_next_month')),
      );
      expect(previousButton.onPressed, isNull);
      expect(nextButton.onPressed, isNotNull);

      reportRepository.requests.clear();
      reportRepository.reportListRequests.clear();
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refreshIndicator.onRefresh();
      await tester.pumpAndSettle();
      expect(reportRepository.requests, isEmpty);
      expect(reportRepository.reportListRequests, [(bulan: 12, tahun: 2026)]);
      expect(scheduleRepository.bulkRequests, 2);
      expect(asatidzRepository.requests, 2);

      await tester.tap(find.byKey(const Key('admin_assessment_next_month')));
      await tester.pumpAndSettle();

      expect(find.text('Januari 2027'), findsOneWidget);
      expect(reportRepository.requests, isEmpty);
      expect(reportRepository.reportListRequests, [
        (bulan: 12, tahun: 2026),
        (bulan: 1, tahun: 2027),
      ]);
      expect(scheduleRepository.bulkRequests, 2);
      expect(asatidzRepository.requests, 2);
    },
  );

  testWidgets('hides incomplete pulse when previous month is complete', (
    tester,
  ) async {
    reportRepository.reportedByPeriod[(bulan: 12, tahun: 2026)] = {
      'santri-lama',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const AdminAssessmentPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = cubit.state as AdminAssessmentLoaded;
    expect(state.previousMonthHasIncompleteAssessment, isFalse);
    expect(
      find.byKey(const Key('admin_assessment_previous_incomplete_indicator')),
      findsNothing,
    );
  });

  testWidgets('error retry keeps the selected previous period', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const AdminAssessmentPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin_assessment_previous_month')));
    await tester.pumpAndSettle();
    reportRepository.failNextReports = (bulan: 12, tahun: 2026);
    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();
    expect(find.textContaining('Gagal memuat data'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Desember 2026'), findsOneWidget);
    expect(reportRepository.requests.last, (bulan: 12, tahun: 2026));
  });
}

MonthlyReport _report({
  required String santriId,
  required int bulan,
  required int tahun,
  MonthlyTargetResult? result,
}) {
  final timestamp = DateTime(tahun, bulan, 28);
  return MonthlyReport(
    id: 'report-$santriId-$tahun-$bulan',
    asatidzId: 'asatidz-1',
    asatidzName: 'Ahmad',
    santriId: santriId,
    santriName: santriId == 'santri-lama' ? 'Ali' : 'Budi',
    bulan: bulan,
    tahun: tahun,
    hafalanTerakhir: 'An-Naba',
    nilaiPerkembangan: 4,
    nilaiAkhlaq: 4,
    targetEvaluation: result == null
        ? null
        : MonthlyTargetEvaluation(
            sourceReportId: 'target-source',
            targetBulan: bulan,
            targetTahun: tahun,
            result: result,
            evaluatedAt: timestamp,
          ),
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

class _FakeAsatidzRepository implements AsatidzRepository {
  int requests = 0;

  @override
  Future<List<AsatidzEntity>> getAsatidzList({
    String? keyword,
    bool? isActive,
    String? gender,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    requests++;
    return [
      AsatidzEntity(
        id: 'asatidz-1',
        name: 'Ahmad',
        nis: '1001',
        jenisKelamin: 'L',
        isActive: true,
      ),
    ];
  }

  @override
  Future<AsatidzDetail> getAsatidzDetail(String id) {
    throw UnimplementedError();
  }

  @override
  Future<String> addAsatidz(AsatidzParams params) {
    throw UnimplementedError();
  }

  @override
  Future<String> getNextNis() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAsatidz(String id, AsatidzParams params) {
    throw UnimplementedError();
  }
}

class _FakeScheduleRepository implements ScheduleRepository {
  int singleRequests = 0;
  int bulkRequests = 0;
  final List<bool> hydrateTeacherNamesRequests = [];

  @override
  Future<Either<Failure, List<Halaqah>>> getAllHalaqahs({
    bool hydrateTeacherNames = true,
  }) async {
    hydrateTeacherNamesRequests.add(hydrateTeacherNames);
    return const Right([
      Halaqah(
        id: 'halaqah-1',
        programId: 'program-1',
        scheduleIds: [],
        name: 'Halaqah 1',
        room: 'A',
        teacherId: 'asatidz-1',
        teacherName: 'Ahmad',
        status: 'active',
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<SantriEntity>>> getSantrisByHalaqahId(
    String halaqahId,
  ) async {
    singleRequests++;
    return Right(_santris());
  }

  @override
  Future<Either<Failure, Map<String, List<SantriEntity>>>>
  getSantrisByHalaqahIds(Iterable<String> halaqahIds) async {
    bulkRequests++;
    return Right({for (final id in halaqahIds) id: _santris()});
  }

  List<SantriEntity> _santris() {
    return [
      SantriEntity(
        id: 'santri-lama',
        name: 'Ali',
        nis: '2001',
        kelas: 'Tahfizh',
        jenisKelamin: 'L',
        isActive: true,
        isFree: false,
        tanggalMasuk: DateTime(2026, 11, 10),
      ),
      SantriEntity(
        id: 'santri-baru',
        name: 'Budi',
        nis: '2002',
        kelas: 'Tahfizh',
        jenisKelamin: 'L',
        isActive: true,
        isFree: false,
        tanggalMasuk: DateTime(2027, 1, 2),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMonthlyReportRepository implements MonthlyReportRepository {
  final Map<({int bulan, int tahun}), Set<String>> reportedByPeriod;
  final Map<({int bulan, int tahun}), List<MonthlyReport>> reportsByPeriod;
  final List<({int bulan, int tahun})> requests = [];
  final List<({int bulan, int tahun})> reportListRequests = [];
  ({int bulan, int tahun})? failNext;
  ({int bulan, int tahun})? failNextReports;

  _FakeMonthlyReportRepository(
    this.reportedByPeriod, {
    this.reportsByPeriod = const {},
  });

  @override
  Future<Either<Failure, Set<String>>> getReportedSantriIds(
    int bulan,
    int tahun,
  ) async {
    final period = (bulan: bulan, tahun: tahun);
    requests.add(period);
    if (failNext == period) {
      failNext = null;
      return const Left(ServerFailure('gangguan sementara'));
    }
    return Right(reportedByPeriod[period] ?? const <String>{});
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsByPeriod(
    int bulan,
    int tahun,
  ) async {
    final period = (bulan: bulan, tahun: tahun);
    reportListRequests.add(period);
    if (failNextReports == period) {
      failNextReports = null;
      return const Left(ServerFailure('gangguan sementara'));
    }
    return Right(reportsByPeriod[period] ?? const []);
  }

  @override
  Future<Either<Failure, MonthlyReport>> createOrUpdateReport(
    MonthlyReport report,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, MonthlyReport?>> getLatestReportBySantri(
    String santriId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, MonthlyReport?>> getReport(
    String santriId,
    int bulan,
    int tahun,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  }) {
    throw UnimplementedError();
  }
}
