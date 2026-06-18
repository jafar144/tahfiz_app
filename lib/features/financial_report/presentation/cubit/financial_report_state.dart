import 'package:khoirunnasyien/features/financial_report/domain/entities/financial_report_data.dart';

sealed class FinancialReportState {}

class FinancialReportInitial extends FinancialReportState {}

class FinancialReportLoading extends FinancialReportState {}

class FinancialReportLoaded extends FinancialReportState {
  final FinancialReportData data;

  FinancialReportLoaded(this.data);
}

class FinancialReportError extends FinancialReportState {
  final String message;

  FinancialReportError(this.message);
}
