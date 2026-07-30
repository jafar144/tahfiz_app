import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_target_carousel.dart';

void main() {
  testWidgets(
    'carousel prioritizes current month and navigates to upcoming target',
    (tester) async {
      final reports = [
        _report(
          id: 'july-report',
          bulan: 7,
          target: const MonthlyTarget(
            bulan: 8,
            tahun: 2026,
            minimum: 'Murojaah empat halaman',
            optimum: 'Menambah enam halaman',
          ),
          evaluation: MonthlyTargetEvaluation(
            sourceReportId: 'june-report',
            targetBulan: 7,
            targetTahun: 2026,
            result: MonthlyTargetResult.minimumAchieved,
            evaluatedAt: DateTime(2026, 7, 29),
          ),
        ),
        _report(
          id: 'june-report',
          bulan: 6,
          target: const MonthlyTarget(
            bulan: 7,
            tahun: 2026,
            minimum: 'Murojaah tiga halaman',
            optimum: 'Menambah lima halaman',
          ),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MonthlyTargetCarousel(
                reports: reports,
                now: DateTime(2026, 7, 15),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimum tercapai').hitTestable(), findsOneWidget);
      expect(find.text('MINIMUM TERCAPAI').hitTestable(), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('monthly-target-next')));
      await tester.pumpAndSettle();

      expect(find.text('Akan datang').hitTestable(), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  test('timeline associates evaluation with its source target', () {
    final source = _report(
      id: 'source',
      bulan: 6,
      target: const MonthlyTarget(
        bulan: 7,
        tahun: 2026,
        minimum: 'Minimum',
        optimum: 'Optimum',
      ),
    );
    final evaluator = _report(
      id: 'evaluator',
      bulan: 7,
      evaluation: MonthlyTargetEvaluation(
        sourceReportId: 'source',
        targetBulan: 7,
        targetTahun: 2026,
        result: MonthlyTargetResult.optimumAchieved,
        evaluatedAt: DateTime(2026, 7, 29),
      ),
    );

    final timeline = MonthlyTargetTimelineEntry.fromReports([
      evaluator,
      source,
    ]);

    expect(timeline, hasLength(1));
    expect(timeline.single.result, MonthlyTargetResult.optimumAchieved);
  });
}

MonthlyReport _report({
  required String id,
  required int bulan,
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
