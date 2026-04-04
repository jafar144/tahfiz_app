import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class SantriMonthlyReportState {
  const SantriMonthlyReportState();
}

class SantriMonthlyReportInitial extends SantriMonthlyReportState {}

class SantriMonthlyReportLoading extends SantriMonthlyReportState {}

class SantriMonthlyReportLoaded extends SantriMonthlyReportState {
  final List<MonthlyReport> reports;

  const SantriMonthlyReportLoaded(this.reports);
}

class SantriMonthlyReportError extends SantriMonthlyReportState {
  final String message;
  const SantriMonthlyReportError(this.message);
}
