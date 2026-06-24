import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class MonthlyReportInputState {
  const MonthlyReportInputState();
}

class MonthlyReportInputInitial extends MonthlyReportInputState {}

class MonthlyReportInputLoading extends MonthlyReportInputState {}

class MonthlyReportInputReady extends MonthlyReportInputState {
  final MonthlyReport? existingReport;

  /// Penilaian terakhir santri sebelum periode ini (untuk referensi).
  final MonthlyReport? latestReport;
  final bool isSaving;

  const MonthlyReportInputReady({
    this.existingReport,
    this.latestReport,
    this.isSaving = false,
  });

  MonthlyReportInputReady copyWith({
    MonthlyReport? existingReport,
    MonthlyReport? latestReport,
    bool? isSaving,
  }) {
    return MonthlyReportInputReady(
      existingReport: existingReport ?? this.existingReport,
      latestReport: latestReport ?? this.latestReport,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class MonthlyReportInputSuccess extends MonthlyReportInputState {
  final String message;
  const MonthlyReportInputSuccess(this.message);
}

class MonthlyReportInputError extends MonthlyReportInputState {
  final String message;
  const MonthlyReportInputError(this.message);
}
