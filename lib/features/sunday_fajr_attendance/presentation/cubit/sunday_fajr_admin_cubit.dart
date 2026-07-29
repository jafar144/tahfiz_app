import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_admin_state.dart';

class SundayFajrAdminCubit extends Cubit<SundayFajrAdminState> {
  SundayFajrAdminCubit(this.repository) : super(const SundayFajrAdminState());

  final SundayFajrAttendanceRepository repository;

  Future<void> load() async {
    emit(
      state.copyWith(status: SundayFajrAdminStatus.loading, clearError: true),
    );
    try {
      final history = await repository.getAttendanceHistory();
      if (isClosed) return;
      emit(
        SundayFajrAdminState(
          status: SundayFajrAdminStatus.loaded,
          history: history,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        SundayFajrAdminState(
          status: SundayFajrAdminStatus.failure,
          history: state.history,
          errorMessage: ErrorHandler.getMessage(error),
        ),
      );
    }
  }
}
