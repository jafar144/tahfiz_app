import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';

abstract class ScheduleState {}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final String selectedGender;
  final List<ScheduleProgram> programs;
  final List<ProgramSchedule> schedules;
  final List<Halaqah> halaqahs;

  ScheduleLoaded({
    required this.selectedGender,
    required this.programs,
    required this.schedules,
    required this.halaqahs,
  });
}

class ScheduleError extends ScheduleState {
  final String message;

  ScheduleError(this.message);
}
