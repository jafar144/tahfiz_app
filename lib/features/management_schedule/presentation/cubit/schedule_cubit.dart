import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository repository;

  ScheduleCubit(this.repository) : super(ScheduleInitial());

  Future<void> loadSchedule(String gender) async {
    emit(ScheduleLoading());

    final programsResult = await repository.getPrograms(gender: gender);

    programsResult.fold(
      ifLeft: (failure) => emit(ScheduleError(failure.message)),
      ifRight: (programs) async {
        List<ProgramSchedule> allSchedules = [];
        List<Halaqah> allHalaqahs = [];

        // Check if no programs found
        if (programs.isEmpty) {
           emit(ScheduleLoaded(
            selectedGender: gender,
            programs: const [],
            schedules: const [],
            halaqahs: const [],
          ));
          return;
        }

        bool hasError = false;
        String errorMessage = '';

        for (var program in programs) {
          final scheduleResult = await repository.getSchedules(programId: program.id);
          
          List<ProgramSchedule> currentProgramSchedules = [];
          scheduleResult.fold(
            ifLeft: (l) { hasError = true; errorMessage = l.message; },
            ifRight: (r) => currentProgramSchedules = r,
          );

          if (hasError) break;
          allSchedules.addAll(currentProgramSchedules);

          final halaqahResult = await repository.getHalaqahs(programId: program.id);
          halaqahResult.fold(
            ifLeft: (l) { 
            },
            ifRight: (r) => allHalaqahs.addAll(r),
          );
        }

        if (hasError) {
          emit(ScheduleError(errorMessage));
        } else {
          emit(ScheduleLoaded(
            selectedGender: gender,
            programs: programs,
            schedules: allSchedules,
            halaqahs: allHalaqahs,
          ));
        }
      },
    );
  }
}
