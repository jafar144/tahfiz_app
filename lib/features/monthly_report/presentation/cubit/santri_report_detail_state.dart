import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class SantriReportDetailState {
  const SantriReportDetailState();
}

class SantriReportDetailLoading extends SantriReportDetailState {}

class SantriReportDetailLoaded extends SantriReportDetailState {
  /// Penilaian yang sedang ditampilkan (paginasi).
  final List<MonthlyReport> reports;

  /// Masih ada data lain yang belum ditampilkan.
  final bool hasMore;

  /// Sedang memuat halaman berikutnya.
  final bool isLoadingMore;

  /// Periode bulan lampau yang belum diisi & masih boleh disusul (terbaru dulu).
  final List<({int bulan, int tahun})> missingPeriods;

  /// Apakah penilaian bulan berjalan sudah ada (untuk menentukan label FAB:
  /// "Edit" vs "Tambah").
  final bool currentMonthFilled;

  /// Target yang berlaku untuk bulan berjalan. Target ini biasanya berasal
  /// dari penilaian bulan sebelumnya.
  final MonthlyTargetProgress? currentMonthTarget;

  /// Target periode yang sudah dipasangkan dengan setiap laporan riwayat.
  /// Key menggunakan ID laporan penilaian, bukan ID laporan pembuat target.
  final Map<String, MonthlyTargetProgress> periodTargetsByReportId;

  const SantriReportDetailLoaded({
    required this.reports,
    required this.hasMore,
    this.isLoadingMore = false,
    this.missingPeriods = const [],
    this.currentMonthFilled = false,
    this.currentMonthTarget,
    this.periodTargetsByReportId = const {},
  });

  SantriReportDetailLoaded copyWith({
    List<MonthlyReport>? reports,
    bool? hasMore,
    bool? isLoadingMore,
    List<({int bulan, int tahun})>? missingPeriods,
    bool? currentMonthFilled,
    MonthlyTargetProgress? currentMonthTarget,
    Map<String, MonthlyTargetProgress>? periodTargetsByReportId,
  }) {
    return SantriReportDetailLoaded(
      reports: reports ?? this.reports,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      missingPeriods: missingPeriods ?? this.missingPeriods,
      currentMonthFilled: currentMonthFilled ?? this.currentMonthFilled,
      currentMonthTarget: currentMonthTarget ?? this.currentMonthTarget,
      periodTargetsByReportId:
          periodTargetsByReportId ?? this.periodTargetsByReportId,
    );
  }
}

class SantriReportDetailError extends SantriReportDetailState {
  final String message;
  const SantriReportDetailError(this.message);
}
