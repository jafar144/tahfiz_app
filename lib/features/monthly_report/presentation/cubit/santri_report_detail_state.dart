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

  const SantriReportDetailLoaded({
    required this.reports,
    required this.hasMore,
    this.isLoadingMore = false,
    this.missingPeriods = const [],
  });

  SantriReportDetailLoaded copyWith({
    List<MonthlyReport>? reports,
    bool? hasMore,
    bool? isLoadingMore,
    List<({int bulan, int tahun})>? missingPeriods,
  }) {
    return SantriReportDetailLoaded(
      reports: reports ?? this.reports,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      missingPeriods: missingPeriods ?? this.missingPeriods,
    );
  }
}

class SantriReportDetailError extends SantriReportDetailState {
  final String message;
  const SantriReportDetailError(this.message);
}
