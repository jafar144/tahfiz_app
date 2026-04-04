import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class MonthlyReportInputState {
  const MonthlyReportInputState();
}

class MonthlyReportInputInitial extends MonthlyReportInputState {}

class MonthlyReportInputLoading extends MonthlyReportInputState {}

class MonthlyReportInputReady extends MonthlyReportInputState {
  final MonthlyReport? existingReport;
  final bool isSaving;

  const MonthlyReportInputReady({
    this.existingReport,
    this.isSaving = false,
  });

  MonthlyReportInputReady copyWith({
    MonthlyReport? existingReport,
    bool? isSaving,
  }) {
    return MonthlyReportInputReady(
      existingReport: existingReport ?? this.existingReport,
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
