import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_target_carousel.dart';

void main() {
  testWidgets(
    'shows only the current month target without carousel navigation',
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

      expect(find.text('Target Bulan Ini'), findsOneWidget);
      expect(find.text('Minimum tercapai').hitTestable(), findsOneWidget);
      expect(find.text('MINIMUM TERCAPAI').hitTestable(), findsOneWidget);
      expect(find.text('Murojaah tiga halaman'), findsOneWidget);
      expect(find.text('Murojaah empat halaman'), findsNothing);
      expect(find.text('Ahmad'), findsOneWidget);
      expect(find.text('Disusun bersama Ahmad'), findsNothing);
      expect(
        find.text('Ikhtiar terarah, dijaga sedikit demi sedikit'),
        findsNothing,
      );
      expect(find.byKey(const Key('monthly-target-page-view')), findsNothing);
      expect(find.byKey(const Key('monthly-target-previous')), findsNothing);
      expect(find.byKey(const Key('monthly-target-next')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('monthly-target-2026-7'))).height,
        lessThan(300),
      );
    },
  );

  testWidgets('does not fall back to a past or future target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MonthlyTargetCarousel(
              reports: [
                _report(
                  id: 'july-report',
                  bulan: 7,
                  target: const MonthlyTarget(
                    bulan: 8,
                    tahun: 2026,
                    minimum: 'Target Agustus minimum',
                    optimum: 'Target Agustus optimum',
                  ),
                ),
              ],
              now: DateTime(2026, 7, 15),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('monthly-target-empty-state')), findsOneWidget);
    expect(find.text('Target Bulan Ini'), findsOneWidget);
    expect(find.text('Target bulan ini belum tersedia'), findsOneWidget);
    expect(find.text('Target Agustus minimum'), findsNothing);
  });

  testWidgets('empty reports keep monthly target carousel hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MonthlyTargetCarousel(reports: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('monthly-target-empty-state')), findsNothing);
    expect(find.text('Target Bulan Ini'), findsNothing);
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
