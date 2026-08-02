enum MonthlyTargetResult {
  notAssessed,
  notAchieved,
  minimumAchieved,
  optimumAchieved;

  static MonthlyTargetResult fromStorage(dynamic value) {
    return switch (value?.toString()) {
      'notAchieved' || 'not_achieved' => MonthlyTargetResult.notAchieved,
      'minimumAchieved' ||
      'minimum_achieved' => MonthlyTargetResult.minimumAchieved,
      'optimumAchieved' ||
      'optimum_achieved' => MonthlyTargetResult.optimumAchieved,
      _ => MonthlyTargetResult.notAssessed,
    };
  }

  String get storageValue => name;

  bool get isAchieved =>
      this == MonthlyTargetResult.minimumAchieved ||
      this == MonthlyTargetResult.optimumAchieved;

  String get label => switch (this) {
    MonthlyTargetResult.notAssessed => 'Belum dinilai',
    MonthlyTargetResult.notAchieved => 'Belum tercapai',
    MonthlyTargetResult.minimumAchieved => 'Target minimum tercapai',
    MonthlyTargetResult.optimumAchieved => 'Target optimum tercapai',
  };
}

class MonthlyTarget {
  final int bulan;
  final int tahun;
  final String minimum;
  final String optimum;

  const MonthlyTarget({
    required this.bulan,
    required this.tahun,
    required this.minimum,
    required this.optimum,
  });

  bool appliesTo(int month, int year) => bulan == month && tahun == year;
}

class MonthlyTargetEvaluation {
  /// ID laporan bulan sebelumnya yang membuat target.
  final String sourceReportId;
  final int targetBulan;
  final int targetTahun;
  final MonthlyTargetResult result;
  final DateTime evaluatedAt;

  const MonthlyTargetEvaluation({
    required this.sourceReportId,
    required this.targetBulan,
    required this.targetTahun,
    required this.result,
    required this.evaluatedAt,
  });

  bool evaluates(String reportId, MonthlyTarget target) {
    if (sourceReportId.isNotEmpty) return sourceReportId == reportId;
    return targetBulan == target.bulan && targetTahun == target.tahun;
  }
}

class MonthlyReport {
  final String id;
  final String asatidzId;
  final String asatidzName;

  /// Gender pengajar ('L' / 'P'), dipakai untuk gelar Ustadz/Ustadzah.
  /// Bisa kosong bila tidak diketahui.
  final String asatidzGender;
  final String santriId;
  final String santriName;
  final int bulan;
  final int tahun;
  final String hafalanTerakhir;
  final int nilaiPerkembangan;
  final int nilaiAkhlaq;
  final String notes;
  final MonthlyTarget? target;
  final MonthlyTargetEvaluation? targetEvaluation;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyReport({
    required this.id,
    required this.asatidzId,
    required this.asatidzName,
    this.asatidzGender = '',
    required this.santriId,
    required this.santriName,
    required this.bulan,
    required this.tahun,
    required this.hafalanTerakhir,
    required this.nilaiPerkembangan,
    required this.nilaiAkhlaq,
    this.notes = '',
    this.target,
    this.targetEvaluation,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Data dummy untuk keperluan skeleton loading.
  factory MonthlyReport.dummy() => MonthlyReport(
    id: 'dummy',
    asatidzId: '',
    asatidzName: 'Ustadz Fulan',
    santriId: '',
    santriName: 'Santri',
    bulan: 1,
    tahun: 2024,
    hafalanTerakhir: 'Al-Baqarah ayat 1-20',
    nilaiPerkembangan: 4,
    nilaiAkhlaq: 4,
    target: const MonthlyTarget(
      bulan: 2,
      tahun: 2024,
      minimum: 'Murojaah 3 halaman dengan lancar',
      optimum: 'Menambah hafalan 5 halaman dengan lancar',
    ),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  /// Gelar pengajar berdasarkan gender: 'Ustadz' / 'Ustadzah' / '' (tak diketahui).
  String get asatidzTitle => switch (asatidzGender) {
    'L' => 'Ustadz',
    'P' => 'Ustadzah',
    _ => '',
  };

  /// Nama pengajar lengkap dengan gelar, mis. "Ustadz Ja'far Assegaf".
  String get asatidzDisplayName =>
      asatidzTitle.isEmpty ? asatidzName : '$asatidzTitle $asatidzName';

  static String getNilaiLabel(int nilai) {
    switch (nilai) {
      case 5:
        return 'Sangat Baik';
      case 4:
        return 'Baik';
      case 3:
        return 'Cukup';
      case 2:
        return 'Kurang';
      case 1:
        return 'Sangat Kurang';
      default:
        return '-';
    }
  }

  static String getNamaBulan(int bulan) {
    const names = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return (bulan >= 1 && bulan <= 12) ? names[bulan] : '-';
  }
}

/// Target yang berlaku pada suatu periode beserta hasil penilaiannya.
///
/// Target bulan berjalan disimpan pada laporan bulan sebelumnya, sementara
/// hasil capaiannya disimpan pada laporan bulan yang dinilai. Objek ini
/// memasangkan kedua data tersebut agar UI tidak keliru menampilkan target
/// bulan berikutnya sebagai target periode laporan.
class MonthlyTargetProgress {
  final String sourceReportId;
  final MonthlyTarget target;
  final MonthlyTargetResult result;

  const MonthlyTargetProgress({
    required this.sourceReportId,
    required this.target,
    required this.result,
  });

  /// Mencari target yang berlaku untuk [assessment] dan memasangkannya dengan
  /// evaluasi yang tersimpan pada penilaian tersebut.
  static MonthlyTargetProgress? forAssessment(
    MonthlyReport assessment,
    Iterable<MonthlyReport> reports,
  ) {
    MonthlyReport? source;

    for (final report in reports) {
      final target = report.target;
      if (target == null ||
          !target.appliesTo(assessment.bulan, assessment.tahun)) {
        continue;
      }

      final evaluation = assessment.targetEvaluation;
      if (evaluation?.evaluates(report.id, target) ?? false) {
        source = report;
        break;
      }

      // Data lama bisa belum memiliki evaluasi. Tetap tampilkan target yang
      // periodenya cocok dan tandai sebagai belum dinilai.
      source ??= report;
    }

    final target = source?.target;
    if (source == null || target == null) return null;

    final evaluation = assessment.targetEvaluation;
    final result = evaluation?.evaluates(source.id, target) ?? false
        ? evaluation!.result
        : MonthlyTargetResult.notAssessed;

    return MonthlyTargetProgress(
      sourceReportId: source.id,
      target: target,
      result: result,
    );
  }

  /// Mencari target untuk [bulan]/[tahun]. Hasil evaluasi ikut dipasangkan
  /// bila laporan untuk periode tersebut sudah tersedia.
  static MonthlyTargetProgress? forPeriod(
    Iterable<MonthlyReport> reports, {
    required int bulan,
    required int tahun,
  }) {
    final allReports = reports is List<MonthlyReport>
        ? reports
        : reports.toList(growable: false);

    for (final report in allReports) {
      if (report.bulan == bulan && report.tahun == tahun) {
        final progress = forAssessment(report, allReports);
        if (progress != null) return progress;
      }
    }

    for (final source in allReports) {
      final target = source.target;
      if (target?.appliesTo(bulan, tahun) ?? false) {
        return MonthlyTargetProgress(
          sourceReportId: source.id,
          target: target!,
          result: MonthlyTargetResult.notAssessed,
        );
      }
    }

    return null;
  }
}
