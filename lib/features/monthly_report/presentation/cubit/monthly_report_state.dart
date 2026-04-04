import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class MonthlyReportState {
  const MonthlyReportState();
}

class MonthlyReportInitial extends MonthlyReportState {}

class MonthlyReportLoading extends MonthlyReportState {}

class MonthlyReportLoaded extends MonthlyReportState {
  final List<SantriEntity> santriList;
  final Map<String, MonthlyReport> reportMap;
  final bool isInWindow;
  final int targetBulan;
  final int targetTahun;
  final int daysRemaining;

  const MonthlyReportLoaded({
    required this.santriList,
    required this.reportMap,
    required this.isInWindow,
    required this.targetBulan,
    required this.targetTahun,
    this.daysRemaining = 0,
  });
}

class MonthlyReportError extends MonthlyReportState {
  final String message;
  const MonthlyReportError(this.message);
}
