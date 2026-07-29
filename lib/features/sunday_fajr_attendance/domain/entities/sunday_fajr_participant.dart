import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';

class SundayFajrParticipant {
  const SundayFajrParticipant({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.santriNis,
    required this.kelas,
    required this.weekKey,
    required this.eventDate,
    required this.status,
    this.izinReason = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String santriId;
  final String santriName;
  final String santriNis;
  final String kelas;
  final String weekKey;
  final DateTime eventDate;
  final SundayFajrAttendanceStatus status;
  final String izinReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  SundayFajrParticipant copyWith({
    SundayFajrAttendanceStatus? status,
    String? izinReason,
    DateTime? updatedAt,
  }) {
    return SundayFajrParticipant(
      id: id,
      santriId: santriId,
      santriName: santriName,
      santriNis: santriNis,
      kelas: kelas,
      weekKey: weekKey,
      eventDate: eventDate,
      status: status ?? this.status,
      izinReason: izinReason ?? this.izinReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SundayFajrParticipantDraft {
  const SundayFajrParticipantDraft({
    required this.santriId,
    required this.santriName,
    required this.santriNis,
    required this.kelas,
    this.status,
    this.izinReason = '',
    this.createdAt,
  });

  final String santriId;
  final String santriName;
  final String santriNis;
  final String kelas;
  final SundayFajrAttendanceStatus? status;
  final String izinReason;
  final DateTime? createdAt;

  bool get hasValidReason =>
      status != SundayFajrAttendanceStatus.izin || izinReason.trim().isNotEmpty;

  bool get isComplete => status != null && hasValidReason;

  SundayFajrParticipantDraft copyWith({
    SundayFajrAttendanceStatus? status,
    bool clearStatus = false,
    String? izinReason,
  }) {
    return SundayFajrParticipantDraft(
      santriId: santriId,
      santriName: santriName,
      santriNis: santriNis,
      kelas: kelas,
      status: clearStatus ? null : status ?? this.status,
      izinReason: izinReason ?? this.izinReason,
      createdAt: createdAt,
    );
  }
}
