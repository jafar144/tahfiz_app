import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/asatidz_attendance.dart';

class AsatidzAttendanceModel extends AsatidzAttendance {
  AsatidzAttendanceModel({
    required super.id,
    required super.asatidzId,
    required super.asatidzName,
    required super.halaqahId,
    required super.halaqahName,
    required super.scheduleId,
    required super.date,
    required super.checkInTime,
    required super.status,
    super.notes,
    required super.createdAt,
    super.substituteAsatidzId,
    super.substituteAsatidzName,
    super.triggeredByRole,
  });

  factory AsatidzAttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AsatidzAttendanceModel(
      id: doc.id,
      asatidzId: data['asatidz_id'] ?? '',
      asatidzName: data['asatidz_name'] ?? '',
      halaqahId: data['halaqah_id'] ?? '',
      halaqahName: data['halaqah_name'] ?? '',
      scheduleId: data['schedule_id'] ?? '',
      date: data['date'] ?? '',
      checkInTime: (data['check_in_time'] as Timestamp).toDate(),
      status: data['status'] ?? 'hadir',
      notes: data['notes'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      substituteAsatidzId: data['substitute_asatidz_id'],
      substituteAsatidzName: data['substitute_asatidz_name'],
      triggeredByRole: data['triggered_by_role'] ?? 'asatidz',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'asatidz_id': asatidzId,
      'asatidz_name': asatidzName,
      'halaqah_id': halaqahId,
      'halaqah_name': halaqahName,
      'schedule_id': scheduleId,
      'date': date,
      'check_in_time': Timestamp.fromDate(checkInTime),
      'status': status,
      'notes': notes,
      'created_at': Timestamp.fromDate(createdAt),
      if (substituteAsatidzId != null)
        'substitute_asatidz_id': substituteAsatidzId,
      if (substituteAsatidzName != null)
        'substitute_asatidz_name': substituteAsatidzName,
      'triggered_by_role': triggeredByRole,
    };
  }
}
