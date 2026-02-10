import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/asatidz/data/datasources/asatidz_remote_datasource.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/asatidz_attendance.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_attendance.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';

class AsatidzRepositoryImpl implements AsatidzRepository {
  final AsatidzRemoteDataSource remoteDataSource;

  AsatidzRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> checkAttendance({
    required String asatidzId,
    required String halaqahId,
    required String scheduleId,
    required DateTime date,
  }) async {
    try {
      final result = await remoteDataSource.checkAttendance(
        asatidzId: asatidzId,
        halaqahId: halaqahId,
        scheduleId: scheduleId,
        date: date,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AsatidzAttendance>> createAttendance({
    required String asatidzId,
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
  }) async {
    try {
      final asatidzName = 'Asatidz'; // TODO: Get from auth/user data
      final result = await remoteDataSource.createAttendance(
        asatidzId: asatidzId,
        asatidzName: asatidzName,
        halaqahId: halaqahId,
        halaqahName: halaqahName,
        scheduleId: scheduleId,
        date: date,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AsatidzAttendance>>> getAttendanceHistory({
    required String asatidzId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getAttendanceHistory(
        asatidzId: asatidzId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SantriAttendance>> createSantriAttendance({
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
    required String asatidzId,
    required String asatidzName,
    required List<SantriAttendanceItem> attendanceList,
  }) async {
    try {
      final result = await remoteDataSource.createSantriAttendance(
        halaqahId: halaqahId,
        halaqahName: halaqahName,
        scheduleId: scheduleId,
        date: date,
        asatidzId: asatidzId,
        asatidzName: asatidzName,
        attendanceList: attendanceList,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SantriAttendance?>> getSantriAttendance({
    required String halaqahId,
    required DateTime date,
  }) async {
    try {
      final result = await remoteDataSource.getSantriAttendance(
        halaqahId: halaqahId,
        date: date,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SantriSetoran>> createSetoran({
    required String santriId,
    required String santriName,
    required String halaqahId,
    required String halaqahName,
    required String asatidzId,
    required String asatidzName,
    required DateTime date,
    required String surah,
    required int ayatAwal,
    required int ayatAkhir,
    required String kualitasHafalan,
    String catatan = '',
  }) async {
    try {
      final result = await remoteDataSource.createSetoran(
        santriId: santriId,
        santriName: santriName,
        halaqahId: halaqahId,
        halaqahName: halaqahName,
        asatidzId: asatidzId,
        asatidzName: asatidzName,
        date: date,
        surah: surah,
        ayatAwal: ayatAwal,
        ayatAkhir: ayatAkhir,
        kualitasHafalan: kualitasHafalan,
        catatan: catatan,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SantriSetoran>>> getSetoranHistory({
    required String santriId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getSetoranHistory(
        santriId: santriId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
