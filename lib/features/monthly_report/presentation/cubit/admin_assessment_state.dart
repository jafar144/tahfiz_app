import 'package:khoirunnasyien/features/monthly_report/domain/entities/pembimbing_assessment.dart';

abstract class AdminAssessmentState {
  const AdminAssessmentState();
}

class AdminAssessmentInitial extends AdminAssessmentState {
  const AdminAssessmentInitial();
}

class AdminAssessmentLoading extends AdminAssessmentState {
  const AdminAssessmentLoading();
}

class AdminAssessmentLoaded extends AdminAssessmentState {
  final int bulan;
  final int tahun;

  /// `true` bila setidaknya ada satu santri yang belum dinilai pada bulan
  /// sebelum bulan berjalan. Status ini mencakup pembimbing putra dan putri.
  final bool previousMonthHasIncompleteAssessment;

  /// Seluruh pembimbing (putra & putri). Difilter per tab di UI.
  final List<PembimbingAssessment> pembimbingList;

  const AdminAssessmentLoaded({
    required this.bulan,
    required this.tahun,
    this.previousMonthHasIncompleteAssessment = false,
    required this.pembimbingList,
  });

  /// Pembimbing untuk gender tertentu ('L'/'P'), tanpa request ulang.
  List<PembimbingAssessment> byGender(String gender) =>
      pembimbingList.where((p) => p.gender == gender).toList();
}

class AdminAssessmentError extends AdminAssessmentState {
  final String message;
  const AdminAssessmentError(this.message);
}
