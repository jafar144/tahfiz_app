import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';

class SundayFajrParticipantModel extends SundayFajrParticipant {
  const SundayFajrParticipantModel({
    required super.id,
    required super.santriId,
    required super.santriName,
    required super.santriNis,
    required super.kelas,
    required super.weekKey,
    required super.eventDate,
    required super.status,
    super.izinReason,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SundayFajrParticipantModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final weekKey = data['week_key'] as String? ?? '';
    final eventDate =
        SundayFajrAttendancePolicy.tryParseWeekKey(weekKey) ??
        (data['event_date'] as Timestamp?)?.toDate().toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? eventDate;
    final status = SundayFajrAttendanceStatus.fromValue(
      data['status'] as String?,
    );

    return SundayFajrParticipantModel(
      id: document.id,
      santriId: data['santri_id'] as String? ?? document.id,
      santriName: data['santri_name'] as String? ?? '',
      santriNis: data['santri_nis']?.toString() ?? '',
      kelas: data['kelas'] as String? ?? '',
      weekKey: weekKey,
      eventDate: SundayFajrAttendancePolicy.canonicalDate(eventDate),
      status: status,
      izinReason: status == SundayFajrAttendanceStatus.izin
          ? (data['izin_reason'] ?? data['reason'] ?? data['notes'] ?? '')
                .toString()
          : '',
      createdAt: createdAt,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? createdAt,
    );
  }
}
