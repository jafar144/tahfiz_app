import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleProgram>>> getPrograms({required String gender});
  Future<Either<Failure, List<ProgramSchedule>>> getSchedules({required String programId});
  Future<Either<Failure, ProgramSchedule>> getScheduleById(String scheduleId);
  Future<Either<Failure, ScheduleProgram>> getProgramById(String programId);
  Future<Either<Failure, List<Halaqah>>> getHalaqahs({required String programId});
  Future<Either<Failure, List<Halaqah>>> getHalaqahsBySchedule(String scheduleId);
  Future<Either<Failure, List<Halaqah>>> getHalaqahsByTeacher(String teacherId);
  Future<Either<Failure, List<Halaqah>>> getAllHalaqahs();
  Future<Either<Failure, void>> updateHalaqah(Halaqah halaqah, List<String> newSantriIds, List<String> removedSantriIds);
  Future<Either<Failure, void>> createHalaqah(Halaqah halaqah, List<String> santriIds);
  Future<Either<Failure, void>> deleteHalaqah(String halaqahId);
  Future<Either<Failure, Halaqah?>> getHalaqahBySantriId(String santriId);

  /// Mengeluarkan santri dari halaqah yang sedang ditempatinya (bila ada).
  Future<Either<Failure, void>> removeSantriFromHalaqah(String santriId);

  /// Memindahkan santri ke halaqah lain (ganti pembimbing lewat halaqah).
  /// Bila [newSession] diisi, `tipe_kelas` santri ikut disamakan dengan sesi
  /// halaqah barunya.
  Future<Either<Failure, void>> moveSantriToHalaqah(
    String santriId,
    String newHalaqahId, {
    String? newSession,
  });
  Future<Either<Failure, List<SantriEntity>>> getSantrisByHalaqahId(String halaqahId);
  Future<Either<Failure, void>> migrateHalaqahIds();
}
