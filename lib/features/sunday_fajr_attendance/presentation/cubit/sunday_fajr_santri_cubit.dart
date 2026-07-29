import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_santri_state.dart';

class SundayFajrSantriCubit extends Cubit<SundayFajrSantriState> {
  SundayFajrSantriCubit({
    required this.repository,
    required this.santriId,
    this.limit = 52,
  }) : super(const SundayFajrSantriState());

  final SundayFajrAttendanceRepository repository;
  final String santriId;
  final int limit;

  Future<void> load() async {
    emit(const SundayFajrSantriState(status: SundayFajrSantriStatus.loading));
    try {
      final history = await repository.getSantriHistory(santriId, limit: limit);
      if (isClosed) return;
      emit(
        SundayFajrSantriState(
          status: SundayFajrSantriStatus.loaded,
          history: history,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        SundayFajrSantriState(
          status: SundayFajrSantriStatus.failure,
          errorMessage: ErrorHandler.getMessage(error),
        ),
      );
    }
  }
}
