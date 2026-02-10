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
      date: (data['date'] as Timestamp).toDate(),
      checkInTime: (data['check_in_time'] as Timestamp).toDate(),
      status: data['status'] ?? 'hadir',
      notes: data['notes'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'asatidz_id': asatidzId,
      'asatidz_name': asatidzName,
      'halaqah_id': halaqahId,
      'halaqah_name': halaqahName,
      'schedule_id': scheduleId,
      'date': Timestamp.fromDate(date),
      'check_in_time': Timestamp.fromDate(checkInTime),
      'status': status,
      'notes': notes,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
