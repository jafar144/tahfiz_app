import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

/// Kelompok rekap target bulanan untuk admin.
///
/// Santri yang tidak mencapai target minimum dipisah sesuai keputusan
/// pembimbing. Data lama tanpa keputusan dianggap [penalized].
enum TargetRecapGroup {
  penalized,
  excused,
  minimum,
  optimum;

  static TargetRecapGroup? of(MonthlyTargetEvaluation evaluation) {
    return switch (evaluation.result) {
      MonthlyTargetResult.notAchieved =>
        evaluation.isExcused
            ? TargetRecapGroup.excused
            : TargetRecapGroup.penalized,
      MonthlyTargetResult.minimumAchieved => TargetRecapGroup.minimum,
      MonthlyTargetResult.optimumAchieved => TargetRecapGroup.optimum,
      MonthlyTargetResult.notAssessed => null,
    };
  }
}

class TargetAchievementEntry {
  final String santriId;
  final String santriName;
  final String asatidzName;
  final TargetRecapGroup group;

  /// Alasan pembimbing membebaskan hukuman; kosong untuk kelompok lain.
  final String penaltyExcuse;

  const TargetAchievementEntry({
    required this.santriId,
    required this.santriName,
    required this.asatidzName,
    required this.group,
    this.penaltyExcuse = '',
  });
}

class TargetAchievementRecap {
  final Map<TargetRecapGroup, List<TargetAchievementEntry>> _entries;

  const TargetAchievementRecap({
    Map<TargetRecapGroup, List<TargetAchievementEntry>> entries = const {},
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
          TargetRecapGroup.of(evaluation) == null) {
        continue;
      }

      final previous = latestBySantri[report.santriId];
      if (previous == null || report.updatedAt.isAfter(previous.updatedAt)) {
        latestBySantri[report.santriId] = report;
      }
    }

    final grouped = <TargetRecapGroup, List<TargetAchievementEntry>>{};
    for (final report in latestBySantri.values) {
      final evaluation = report.targetEvaluation!;
      final group = TargetRecapGroup.of(evaluation)!;
      grouped
          .putIfAbsent(group, () => [])
          .add(
            TargetAchievementEntry(
              santriId: report.santriId,
              santriName: report.santriName,
              asatidzName: report.asatidzName,
              group: group,
              penaltyExcuse: group == TargetRecapGroup.excused
                  ? evaluation.penaltyExcuse
                  : '',
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
          Map<TargetRecapGroup, List<TargetAchievementEntry>>.unmodifiable({
            for (final entry in grouped.entries)
              entry.key: List<TargetAchievementEntry>.unmodifiable(entry.value),
          }),
    );
  }

  List<TargetAchievementEntry> entriesFor(TargetRecapGroup group) =>
      _entries[group] ?? const [];

  int countFor(TargetRecapGroup group) => entriesFor(group).length;

  int get total => TargetRecapGroup.values.fold(
    0,
    (total, group) => total + countFor(group),
  );
}
