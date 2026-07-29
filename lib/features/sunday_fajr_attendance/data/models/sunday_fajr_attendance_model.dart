import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';

class SundayFajrAttendanceModel extends SundayFajrAttendance {
  const SundayFajrAttendanceModel({
    required super.id,
    required super.weekKey,
    required super.eventDate,
    required super.participantCount,
    required super.totalHadir,
    required super.totalIzin,
    required super.totalAlpha,
    required super.revision,
    required super.schemaVersion,
    required super.createdBy,
    required super.createdAt,
    required super.updatedBy,
    required super.updatedAt,
  });

  factory SundayFajrAttendanceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final storedWeekKey = data['week_key'] as String?;
    final timestampDate = (data['event_date'] as Timestamp?)?.toDate().toUtc();
    final eventDate =
        SundayFajrAttendancePolicy.tryParseWeekKey(document.id) ??
        SundayFajrAttendancePolicy.tryParseWeekKey(storedWeekKey ?? '') ??
        timestampDate ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? eventDate;

    return SundayFajrAttendanceModel(
      id: document.id,
      weekKey: (data['week_key'] as String?)?.trim().isNotEmpty == true
          ? data['week_key'] as String
          : document.id,
      eventDate: SundayFajrAttendancePolicy.canonicalDate(eventDate),
      participantCount: _intValue(data['participant_count']),
      totalHadir: _intValue(data['total_hadir']),
      totalIzin: _intValue(data['total_izin']),
      totalAlpha: _intValue(data['total_alpha']),
      revision: _intValue(data['revision'], fallback: 1),
      schemaVersion: _intValue(data['schema_version'], fallback: 1),
      createdBy: data['created_by'] as String? ?? '',
      createdAt: createdAt,
      updatedBy: data['updated_by'] as String? ?? '',
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? createdAt,
    );
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
