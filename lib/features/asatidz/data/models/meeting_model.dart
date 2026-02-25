import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/meeting.dart';

class MeetingModel extends Meeting {
  MeetingModel({
    required super.id,
    required super.date,
    required super.halaqahId,
    required super.scheduleId,
    required super.asatidzAttendanceId,
    required super.asatidzId,
    required super.asatidzName,
    super.createdByRole,
    required super.createdAt,
  });

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      date: data['date'] ?? '',
      halaqahId: data['halaqah_id'] ?? '',
      scheduleId: data['schedule_id'] ?? '',
      asatidzAttendanceId: data['asatidz_attendance_id'] ?? '',
      asatidzId: data['asatidz_id'] ?? '',
      asatidzName: data['asatidz_name'] ?? '',
      createdByRole: data['created_by_role'] ?? 'asatidz',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'halaqah_id': halaqahId,
      'schedule_id': scheduleId,
      'asatidz_attendance_id': asatidzAttendanceId,
      'asatidz_id': asatidzId,
      'asatidz_name': asatidzName,
      'created_by_role': createdByRole,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
