import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleProgram>>> getPrograms({required String gender});
  Future<Either<Failure, List<ProgramSchedule>>> getSchedules({required String programId});
  Future<Either<Failure, List<Halaqah>>> getHalaqahs({required String programId});
  Future<Either<Failure, void>> updateHalaqah(Halaqah halaqah);
  Future<Either<Failure, void>> createHalaqah(Halaqah halaqah);
}
