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

  const SantriReportDetailLoaded({
    required this.reports,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  SantriReportDetailLoaded copyWith({
    List<MonthlyReport>? reports,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SantriReportDetailLoaded(
      reports: reports ?? this.reports,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SantriReportDetailError extends SantriReportDetailState {
  final String message;
  const SantriReportDetailError(this.message);
}
