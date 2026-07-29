import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';

class SundayFajrFakeRepository implements SundayFajrAttendanceRepository {
  final Map<String, SundayFajrAttendance> attendanceByWeek = {};
  final Map<String, List<SundayFajrParticipant>> participantsByWeek = {};
  List<SantriEntity> eligibleSantri = [];
  List<SundayFajrParticipant> santriHistory = [];
  Object? saveError;

  int saveCallCount = 0;
  int? lastExpectedRevision;
  List<SundayFajrParticipant>? lastSavedParticipants;

  @override
  Future<SundayFajrAttendance?> getAttendance(String weekKey) async {
    return attendanceByWeek[weekKey];
  }

  @override
  Future<List<SundayFajrAttendance>> getAttendanceHistory({
    int limit = 52,
  }) async {
    final history = attendanceByWeek.values.toList()
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return history.take(limit).toList();
  }

  @override
  Future<List<SantriEntity>> getEligibleSantri() async {
    return List<SantriEntity>.of(eligibleSantri);
  }

  @override
  Future<SundayFajrParticipant?> getLatestSantriAttendance(
    String santriId,
  ) async {
    final history = await getSantriHistory(santriId, limit: 1);
    return history.firstOrNull;
  }

  @override
  Future<List<SundayFajrParticipant>> getParticipants(String weekKey) async {
    return List<SundayFajrParticipant>.of(
      participantsByWeek[weekKey] ?? const [],
    );
  }

  @override
  Future<List<SundayFajrParticipant>> getSantriHistory(
    String santriId, {
    int limit = 52,
  }) async {
    return santriHistory
        .where((participant) => participant.santriId == santriId)
        .take(limit)
        .toList();
  }

  @override
  Future<SundayFajrAttendance> saveAttendance({
    required DateTime eventDate,
    required List<SundayFajrParticipant> participants,
    required String actorId,
    required int expectedRevision,
  }) async {
    saveCallCount++;
    lastExpectedRevision = expectedRevision;
    lastSavedParticipants = List<SundayFajrParticipant>.of(participants);
    if (saveError case final error?) throw error;

    final weekKey = SundayFajrAttendancePolicy.weekKey(eventDate);
    final existing = attendanceByWeek[weekKey];
    if ((existing?.revision ?? 0) != expectedRevision) {
      throw const SundayFajrRevisionConflictException();
    }

    final now = DateTime.utc(2026, 7, 29);
    final result = SundayFajrAttendance(
      id: weekKey,
      weekKey: weekKey,
      eventDate: SundayFajrAttendancePolicy.canonicalDate(eventDate),
      participantCount: participants.length,
      totalHadir: participants
          .where((item) => item.status.value == 'hadir')
          .length,
      totalIzin: participants
          .where((item) => item.status.value == 'izin')
          .length,
      totalAlpha: participants
          .where((item) => item.status.value == 'alpha')
          .length,
      revision: expectedRevision + 1,
      schemaVersion: 1,
      createdBy: existing?.createdBy ?? actorId,
      createdAt: existing?.createdAt ?? now,
      updatedBy: actorId,
      updatedAt: now,
    );
    attendanceByWeek[weekKey] = result;
    participantsByWeek[weekKey] = List<SundayFajrParticipant>.of(participants);
    return result;
  }
}

SantriEntity sundayFajrTestSantri({
  required String id,
  required String name,
  String nis = '1001',
  String kelas = 'Tahfiz 1',
  String gender = 'L',
  bool isActive = true,
}) {
  return SantriEntity(
    id: id,
    name: name,
    nis: nis,
    kelas: kelas,
    jenisKelamin: gender,
    isActive: isActive,
    isFree: false,
  );
}

SundayFajrAttendance sundayFajrTestAttendance({
  required DateTime eventDate,
  int revision = 1,
  int participantCount = 1,
  int totalHadir = 1,
  int totalIzin = 0,
  int totalAlpha = 0,
}) {
  final weekKey = SundayFajrAttendancePolicy.weekKey(eventDate);
  final now = DateTime.utc(2026, 7, 29);
  return SundayFajrAttendance(
    id: weekKey,
    weekKey: weekKey,
    eventDate: eventDate,
    participantCount: participantCount,
    totalHadir: totalHadir,
    totalIzin: totalIzin,
    totalAlpha: totalAlpha,
    revision: revision,
    schemaVersion: 1,
    createdBy: 'admin-1',
    createdAt: now,
    updatedBy: 'admin-1',
    updatedAt: now,
  );
}
