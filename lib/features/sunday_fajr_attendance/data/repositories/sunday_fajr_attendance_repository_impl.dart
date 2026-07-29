import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/data/datasources/sunday_fajr_attendance_remote_datasource.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';

class SundayFajrAttendanceRepositoryImpl
    implements SundayFajrAttendanceRepository {
  SundayFajrAttendanceRepositoryImpl(this.remoteDataSource);

  final SundayFajrAttendanceRemoteDataSource remoteDataSource;

  @override
  Future<List<SundayFajrAttendance>> getAttendanceHistory({int limit = 52}) =>
      remoteDataSource.getAttendanceHistory(limit: limit);

  @override
  Future<SundayFajrAttendance?> getAttendance(String weekKey) =>
      remoteDataSource.getAttendance(weekKey);

  @override
  Future<List<SundayFajrParticipant>> getParticipants(String weekKey) =>
      remoteDataSource.getParticipants(weekKey);

  @override
  Future<List<SantriEntity>> getEligibleSantri() =>
      remoteDataSource.getEligibleSantri();

  @override
  Future<SundayFajrAttendance> saveAttendance({
    required DateTime eventDate,
    required List<SundayFajrParticipant> participants,
    required String actorId,
    required int expectedRevision,
  }) {
    return remoteDataSource.saveAttendance(
      eventDate: eventDate,
      participants: participants,
      actorId: actorId,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<List<SundayFajrParticipant>> getSantriHistory(
    String santriId, {
    int limit = 52,
  }) => remoteDataSource.getSantriHistory(santriId, limit: limit);

  @override
  Future<SundayFajrParticipant?> getLatestSantriAttendance(String santriId) =>
      remoteDataSource.getLatestSantriAttendance(santriId);
}
