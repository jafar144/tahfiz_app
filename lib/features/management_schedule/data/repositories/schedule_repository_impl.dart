import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_schedule/data/datasource/schedule_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';


class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;

  ScheduleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahs({required String programId}) async {
    try {
      final result = await remoteDataSource.getHalaqahs(programId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahsBySchedule(String scheduleId) async {
    try {
      final result = await remoteDataSource.getHalaqahsBySchedule(scheduleId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleProgram>>> getPrograms({required String gender}) async {
    try {
      final result = await remoteDataSource.getPrograms(gender);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProgramSchedule>>> getSchedules({required String programId}) async {
    try {
      final result = await remoteDataSource.getSchedules(programId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateHalaqah(Halaqah halaqah) async {
    try {
      final model = HalaqahModel(
        id: halaqah.id,
        programId: halaqah.programId,
        scheduleIds: halaqah.scheduleIds,
        name: halaqah.name,
        room: halaqah.room,
        teacherId: halaqah.teacherId,
        teacherName: halaqah.teacherName,
        status: halaqah.status,
        santris: halaqah.santris,
      );
      await remoteDataSource.updateHalaqah(model);
      return const Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createHalaqah(Halaqah halaqah) async {
    try {
      final model = HalaqahModel(
        id: halaqah.id,
        programId: halaqah.programId,
        scheduleIds: halaqah.scheduleIds,
        name: halaqah.name,
        room: halaqah.room,
        teacherId: halaqah.teacherId,
        teacherName: halaqah.teacherName,
        status: halaqah.status,
        santris: halaqah.santris,
      );
      await remoteDataSource.createHalaqah(model);
      return const Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProgramSchedule>> getScheduleById(String scheduleId) async {
    try {
      final result = await remoteDataSource.getScheduleById(scheduleId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahsByTeacher(String teacherId) async {
    try {
      final result = await remoteDataSource.getHalaqahsByTeacher(teacherId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
