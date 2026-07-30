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

  /// Laporan sebelumnya yang membuat target untuk periode yang sedang dinilai.
  /// Null untuk data lama atau bila belum pernah ada target.
  final MonthlyReport? targetToEvaluate;
  final bool isSaving;

  const MonthlyReportInputReady({
    this.existingReport,
    this.latestReport,
    this.targetToEvaluate,
    this.isSaving = false,
  });

  MonthlyReportInputReady copyWith({
    MonthlyReport? existingReport,
    MonthlyReport? latestReport,
    MonthlyReport? targetToEvaluate,
    bool? isSaving,
  }) {
    return MonthlyReportInputReady(
      existingReport: existingReport ?? this.existingReport,
      latestReport: latestReport ?? this.latestReport,
      targetToEvaluate: targetToEvaluate ?? this.targetToEvaluate,
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
