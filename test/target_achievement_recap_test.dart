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

    expect(recap.countFor(TargetRecapGroup.penalized), 1);
    expect(recap.countFor(TargetRecapGroup.excused), 0);
    expect(recap.countFor(TargetRecapGroup.minimum), 1);
    expect(recap.countFor(TargetRecapGroup.optimum), 1);
    expect(recap.total, 3);
    expect(
      recap.entriesFor(TargetRecapGroup.minimum).single.santriId,
      'santri-a',
    );
  });

  test(
    'not achieved splits by penalty decision; legacy counts as penalized',
    () {
      final recap = TargetAchievementRecap.fromReports(
        [
          _report(
            'a',
            'santri-a',
            'Ahmad',
            MonthlyTargetResult.notAchieved,
            penalty: MonthlyPenaltyDecision.penalized,
          ),
          _report(
            'b',
            'santri-b',
            'Bilal',
            MonthlyTargetResult.notAchieved,
            penalty: MonthlyPenaltyDecision.excused,
            excuse: 'Sakit dua pekan',
          ),
          // Data sebelum fitur ini ada: tanpa keputusan.
          _report('c', 'santri-c', 'Hasan', MonthlyTargetResult.notAchieved),
        ],
        bulan: 8,
        tahun: 2026,
      );

      expect(
        recap.entriesFor(TargetRecapGroup.penalized).map((e) => e.santriName),
        ['Ahmad', 'Hasan'],
      );
      final excused = recap.entriesFor(TargetRecapGroup.excused).single;
      expect(excused.santriName, 'Bilal');
      expect(excused.penaltyExcuse, 'Sakit dua pekan');
      expect(
        recap.entriesFor(TargetRecapGroup.penalized).first.penaltyExcuse,
        isEmpty,
      );
    },
  );

  testWidgets('panel shows four groups and opens the selected santri list', (
    tester,
  ) async {
    final recap = TargetAchievementRecap.fromReports(
      [
        _report('a', 'santri-a', 'Ahmad', MonthlyTargetResult.notAchieved),
        _report(
          'd',
          'santri-d',
          'Hasan',
          MonthlyTargetResult.notAchieved,
          penalty: MonthlyPenaltyDecision.excused,
          excuse: 'Sakit tifus',
        ),
        _report('b', 'santri-b', 'Bilal', MonthlyTargetResult.minimumAchieved),
        _report('c', 'santri-c', 'Zaid', MonthlyTargetResult.optimumAchieved),
      ],
      bulan: 8,
      tahun: 2026,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TargetAchievementRecapPanel(
                recap: recap,
                periodLabel: 'Agustus 2026',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('target_recap_penalized')), findsOneWidget);
    expect(find.byKey(const Key('target_recap_excused')), findsOneWidget);
    expect(find.byKey(const Key('target_recap_minimum')), findsOneWidget);
    expect(find.byKey(const Key('target_recap_optimum')), findsOneWidget);
    expect(find.text('4 santri sudah dievaluasi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('target_recap_minimum')));
    await tester.pumpAndSettle();

    expect(find.text('1 santri pada Agustus 2026'), findsOneWidget);
    expect(find.text('Bilal'), findsOneWidget);
    expect(find.text('Pembimbing: Ustadz Ahmad'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup daftar santri'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('target_recap_excused')));
    await tester.pumpAndSettle();

    expect(find.text('Hasan'), findsOneWidget);
    expect(find.text('Sakit tifus'), findsOneWidget);
    expect(find.text('Ahmad'), findsNothing);
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
  MonthlyPenaltyDecision penalty = MonthlyPenaltyDecision.undecided,
  String excuse = '',
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
      penalty: penalty,
      penaltyExcuse: excuse,
    ),
    createdAt: DateTime(tahun, bulan, 28),
    updatedAt: DateTime(tahun, bulan, updatedDay),
  );
}
