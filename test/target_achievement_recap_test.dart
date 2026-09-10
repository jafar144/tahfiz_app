import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/target_achievement_recap.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/target_achievement_recap_panel.dart';

void main() {
  test('recap uses explicit results and latest report per santri', () {
    final reports = [
      _report('a-old', 'santri-a', 'Zaid', MonthlyTargetResult.notAchieved),
      _report(
        'a-new',
        'santri-a',
        'Zaid',
        MonthlyTargetResult.minimumAchieved,
        updatedDay: 29,
      ),
      _report('b', 'santri-b', 'Ahmad', MonthlyTargetResult.notAchieved),
      _report('c', 'santri-c', 'Bilal', MonthlyTargetResult.optimumAchieved),
      _report('d', 'santri-d', 'Umar', MonthlyTargetResult.notAssessed),
      _report(
        'wrong-period',
        'santri-e',
        'Ali',
        MonthlyTargetResult.optimumAchieved,
        bulan: 7,
      ),
    ];

    final recap = TargetAchievementRecap.fromReports(
      reports,
      bulan: 8,
      tahun: 2026,
    );

    expect(recap.countFor(MonthlyTargetResult.notAchieved), 1);
    expect(recap.countFor(MonthlyTargetResult.minimumAchieved), 1);
    expect(recap.countFor(MonthlyTargetResult.optimumAchieved), 1);
    expect(recap.total, 3);
    expect(
      recap.entriesFor(MonthlyTargetResult.minimumAchieved).single.santriId,
      'santri-a',
    );
  });

  testWidgets('panel shows three groups and opens the selected santri list', (
    tester,
  ) async {
    final recap = TargetAchievementRecap.fromReports(
      [
        _report('a', 'santri-a', 'Ahmad', MonthlyTargetResult.notAchieved),
        _report('b', 'santri-b', 'Bilal', MonthlyTargetResult.minimumAchieved),
        _report('c', 'santri-c', 'Zaid', MonthlyTargetResult.optimumAchieved),
      ],
      bulan: 8,
      tahun: 2026,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TargetAchievementRecapPanel(recap: recap)),
      ),
    );

    expect(find.byKey(const Key('target_recap_not_achieved')), findsOneWidget);
    expect(find.byKey(const Key('target_recap_minimum')), findsOneWidget);
    expect(find.byKey(const Key('target_recap_optimum')), findsOneWidget);

    await tester.tap(find.byKey(const Key('target_recap_minimum')));
    await tester.pumpAndSettle();

    expect(find.text('Target minimum'), findsOneWidget);
    expect(find.text('Bilal'), findsOneWidget);
    expect(find.text('Pembimbing: Ustadz Ahmad'), findsOneWidget);
  });
}

MonthlyReport _report(
  String id,
  String santriId,
  String santriName,
  MonthlyTargetResult result, {
  int bulan = 8,
  int tahun = 2026,
  int updatedDay = 28,
}) {
  return MonthlyReport(
    id: id,
    asatidzId: 'asatidz-1',
    asatidzName: 'Ustadz Ahmad',
    santriId: santriId,
    santriName: santriName,
    bulan: bulan,
    tahun: tahun,
    hafalanTerakhir: 'An-Naba',
    nilaiPerkembangan: 4,
    nilaiAkhlaq: 4,
    targetEvaluation: MonthlyTargetEvaluation(
      sourceReportId: 'source-$santriId',
      targetBulan: bulan,
      targetTahun: tahun,
      result: result,
      evaluatedAt: DateTime(tahun, bulan, updatedDay),
    ),
    createdAt: DateTime(tahun, bulan, 28),
    updatedAt: DateTime(tahun, bulan, updatedDay),
  );
}
