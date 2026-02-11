import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/asatidz_attendance.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_attendance.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';

abstract class AsatidzRepository {
  Future<Either<Failure, bool>> checkAttendance({
    required String asatidzId,
    required String halaqahId,
    required String scheduleId,
    required DateTime date,
  });

  Future<Either<Failure, AsatidzAttendance>> createAttendance({
    required String asatidzId,
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
  });

  Future<Either<Failure, List<AsatidzAttendance>>> getAttendanceHistory({
    required String asatidzId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, SantriAttendance>> createSantriAttendance({
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
    required String asatidzId,
    required String asatidzName,
    required List<SantriAttendanceItem> attendanceList,
  });

  Future<Either<Failure, SantriAttendance?>> getSantriAttendance({
    required String halaqahId,
    required DateTime date,
  });

  Future<Either<Failure, SantriSetoran>> createSetoran({
    required String santriId,
    required String santriName,
    required String halaqahId,
    required String halaqahName,
    required String asatidzId,
    required String asatidzName,
    required DateTime date,
    required String surah,
    String catatan,
  });

  Future<Either<Failure, void>> updateSetoran({
    required String setoranId,
    required String surah,
    required String catatan,
  });

  Future<Either<Failure, List<SantriSetoran>>> getSetoranHistory({
    required String santriId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
