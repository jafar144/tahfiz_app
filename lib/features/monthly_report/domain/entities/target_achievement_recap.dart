import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

class TargetAchievementEntry {
  final String santriId;
  final String santriName;
  final String asatidzName;
  final MonthlyTargetResult result;

  const TargetAchievementEntry({
    required this.santriId,
    required this.santriName,
    required this.asatidzName,
    required this.result,
  });
}

class TargetAchievementRecap {
  static const supportedResults = <MonthlyTargetResult>{
    MonthlyTargetResult.notAchieved,
    MonthlyTargetResult.minimumAchieved,
    MonthlyTargetResult.optimumAchieved,
  };

  final Map<MonthlyTargetResult, List<TargetAchievementEntry>> _entries;

  const TargetAchievementRecap({
    Map<MonthlyTargetResult, List<TargetAchievementEntry>> entries = const {},
  }) : _entries = entries;

  factory TargetAchievementRecap.fromReports(
    Iterable<MonthlyReport> reports, {
    required int bulan,
    required int tahun,
  }) {
    final latestBySantri = <String, MonthlyReport>{};
    for (final report in reports) {
      final evaluation = report.targetEvaluation;
      if (report.bulan != bulan ||
          report.tahun != tahun ||
          evaluation == null ||
          evaluation.targetBulan != bulan ||
          evaluation.targetTahun != tahun ||
          !supportedResults.contains(evaluation.result)) {
        continue;
      }

      final previous = latestBySantri[report.santriId];
      if (previous == null || report.updatedAt.isAfter(previous.updatedAt)) {
        latestBySantri[report.santriId] = report;
      }
    }

    final grouped = <MonthlyTargetResult, List<TargetAchievementEntry>>{};
    for (final report in latestBySantri.values) {
      final result = report.targetEvaluation!.result;
      grouped
          .putIfAbsent(result, () => [])
          .add(
            TargetAchievementEntry(
              santriId: report.santriId,
              santriName: report.santriName,
              asatidzName: report.asatidzName,
              result: result,
            ),
          );
    }

    for (final entries in grouped.values) {
      entries.sort(
        (a, b) =>
            a.santriName.toLowerCase().compareTo(b.santriName.toLowerCase()),
      );
    }

    return TargetAchievementRecap(
      entries:
          Map<MonthlyTargetResult, List<TargetAchievementEntry>>.unmodifiable({
            for (final entry in grouped.entries)
              entry.key: List<TargetAchievementEntry>.unmodifiable(entry.value),
          }),
    );
  }

  List<TargetAchievementEntry> entriesFor(MonthlyTargetResult result) =>
      _entries[result] ?? const [];

  int countFor(MonthlyTargetResult result) => entriesFor(result).length;

  int get total =>
      supportedResults.fold(0, (total, result) => total + countFor(result));
}
