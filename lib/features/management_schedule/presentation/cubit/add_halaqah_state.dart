import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';

abstract class AddHalaqahState {}

class AddHalaqahInitial extends AddHalaqahState {}

class AddHalaqahLoading extends AddHalaqahState {}

class AddHalaqahLoaded extends AddHalaqahState {
  final List<ScheduleProgram> sessions;
  final List<ProgramSchedule> schedules;
  final List<AsatidzEntity> asatidzList;
  final List<SantriEntity> santriList;

  final List<String> unavailableTeacherIds;
  final List<String> unavailableSantriIds;

  AddHalaqahLoaded({
    required this.sessions,
    required this.schedules,
    required this.asatidzList,
    required this.santriList,
    this.unavailableTeacherIds = const [],
    this.unavailableSantriIds = const [],
  });

  AddHalaqahLoaded copyWith({
    List<ScheduleProgram>? sessions,
    List<ProgramSchedule>? schedules,
    List<AsatidzEntity>? asatidzList,
    List<SantriEntity>? santriList,
    List<String>? unavailableTeacherIds,
    List<String>? unavailableSantriIds,
  }) {
    return AddHalaqahLoaded(
      sessions: sessions ?? this.sessions,
      schedules: schedules ?? this.schedules,
      asatidzList: asatidzList ?? this.asatidzList,
      santriList: santriList ?? this.santriList,
      unavailableTeacherIds:
          unavailableTeacherIds ?? this.unavailableTeacherIds,
      unavailableSantriIds: unavailableSantriIds ?? this.unavailableSantriIds,
    );
  }
}

class AddHalaqahSuccess extends AddHalaqahState {}

class AddHalaqahError extends AddHalaqahState {
  final String message;

  AddHalaqahError(this.message);
}
