import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';

abstract class SundayFajrAttendanceRepository {
  Future<List<SundayFajrAttendance>> getAttendanceHistory({int limit = 52});

  Future<SundayFajrAttendance?> getAttendance(String weekKey);

  Future<List<SundayFajrParticipant>> getParticipants(String weekKey);

  Future<List<SantriEntity>> getEligibleSantri();

  Future<SundayFajrAttendance> saveAttendance({
    required DateTime eventDate,
    required List<SundayFajrParticipant> participants,
    required String actorId,
    required int expectedRevision,
  });

  Future<List<SundayFajrParticipant>> getSantriHistory(
    String santriId, {
    int limit = 52,
  });

  Future<SundayFajrParticipant?> getLatestSantriAttendance(String santriId);
}

class SundayFajrRevisionConflictException implements Exception {
  const SundayFajrRevisionConflictException();

  @override
  String toString() =>
      'Data absensi telah diperbarui admin lain. Muat ulang sebelum menyimpan.';
}

class SundayFajrLockedException implements Exception {
  const SundayFajrLockedException();

  @override
  String toString() =>
      'Absensi ini sudah terkunci karena melewati batas satu minggu.';
}

class SundayFajrRosterTooLargeException implements Exception {
  const SundayFajrRosterTooLargeException();

  @override
  String toString() =>
      'Jumlah peserta melebihi batas penyimpanan satu kali proses.';
}
