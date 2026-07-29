import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/data/datasource/schedule_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/exceptions/halaqah_conflict_exception.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;

  ScheduleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahs({
    required String programId,
  }) async {
    try {
      final result = await remoteDataSource.getHalaqahs(programId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahsBySchedule(
    String scheduleId,
  ) async {
    try {
      final result = await remoteDataSource.getHalaqahsBySchedule(scheduleId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleProgram>>> getPrograms({
    required String gender,
  }) async {
    try {
      final result = await remoteDataSource.getPrograms(gender);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduleProgram>> getProgramById(
    String programId,
  ) async {
    try {
      final result = await remoteDataSource.getProgramById(programId);
      final entity = ScheduleProgram(
        id: result.id,
        name: result.name,
        gender: result.gender,
      );
      return Either.right(entity);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProgramSchedule>>> getSchedules({
    required String programId,
  }) async {
    try {
      final result = await remoteDataSource.getSchedules(programId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateHalaqah(
    Halaqah halaqah,
    List<String> finalSantriIds,
  ) async {
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
        santriCount: finalSantriIds.length,
      );
      await remoteDataSource.updateHalaqah(model, finalSantriIds);
      return const Either.right(null);
    } on HalaqahConflictException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createHalaqah(
    Halaqah halaqah,
    List<String> santriIds,
  ) async {
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
        santriCount: santriIds.length,
      );
      await remoteDataSource.createHalaqah(model, santriIds);
      return const Either.right(null);
    } on HalaqahConflictException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHalaqah(String halaqahId) async {
    try {
      await remoteDataSource.deleteHalaqah(halaqahId);
      return const Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProgramSchedule>> getScheduleById(
    String scheduleId,
  ) async {
    try {
      final result = await remoteDataSource.getScheduleById(scheduleId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahsByTeacher(
    String teacherId,
  ) async {
    try {
      final result = await remoteDataSource.getHalaqahsByTeacher(teacherId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getAllHalaqahs() async {
    try {
      final result = await remoteDataSource.getAllHalaqahs();
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Halaqah?>> getHalaqahBySantriId(
    String santriId,
  ) async {
    try {
      final result = await remoteDataSource.getHalaqahBySantriId(santriId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeSantriFromHalaqah(String santriId) async {
    try {
      await remoteDataSource.removeSantriFromHalaqah(santriId);
      return const Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> moveSantriToHalaqah(
    String santriId,
    String newHalaqahId, {
    String? newSession,
  }) async {
    try {
      await remoteDataSource.moveSantriToHalaqah(
        santriId,
        newHalaqahId,
        newSession: newSession,
      );
      return const Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SantriEntity>>> getSantrisByHalaqahId(
    String halaqahId,
  ) async {
    try {
      final result = await remoteDataSource.getSantrisByHalaqahId(halaqahId);
      return Either.right(result);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> migrateHalaqahIds() async {
    try {
      await remoteDataSource.migrateHalaqahIds();
      return const Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
