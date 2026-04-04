import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_monthly_report_state.dart';

class SantriMonthlyReportCubit extends Cubit<SantriMonthlyReportState> {
  final MonthlyReportRepository repository;

  SantriMonthlyReportCubit({required this.repository})
      : super(SantriMonthlyReportInitial());

  Future<void> loadReports(String santriId) async {
    emit(SantriMonthlyReportLoading());

    try {
      final result = await repository.getReportsBySantri(santriId);

      result.fold(
        ifLeft: (failure) => emit(SantriMonthlyReportError(failure.message)),
        ifRight: (reports) => emit(SantriMonthlyReportLoaded(reports)),
      );
    } catch (e) {
      emit(SantriMonthlyReportError(e.toString()));
    }
  }
}
