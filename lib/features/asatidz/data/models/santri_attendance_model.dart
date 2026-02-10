import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_attendance.dart';

class SantriAttendanceItemModel extends SantriAttendanceItem {
  SantriAttendanceItemModel({
    required super.santriId,
    required super.santriName,
    required super.status,
    super.notes,
  });

  factory SantriAttendanceItemModel.fromMap(Map<String, dynamic> map) {
    return SantriAttendanceItemModel(
      santriId: map['santri_id'] ?? '',
      santriName: map['santri_name'] ?? '',
      status: map['status'] ?? 'alpha',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'santri_id': santriId,
      'santri_name': santriName,
      'status': status,
      'notes': notes,
    };
  }
}

class SantriAttendanceModel extends SantriAttendance {
  SantriAttendanceModel({
    required super.id,
    required super.halaqahId,
    required super.halaqahName,
    required super.scheduleId,
    required super.date,
    required super.asatidzId,
    required super.asatidzName,
    required super.attendanceList,
    required super.totalPresent,
    required super.totalAbsent,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SantriAttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final attendanceListData = data['attendance_list'] as List<dynamic>? ?? [];
    
    return SantriAttendanceModel(
      id: doc.id,
      halaqahId: data['halaqah_id'] ?? '',
      halaqahName: data['halaqah_name'] ?? '',
      scheduleId: data['schedule_id'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      asatidzId: data['asatidz_id'] ?? '',
      asatidzName: data['asatidz_name'] ?? '',
      attendanceList: attendanceListData
          .map((item) => SantriAttendanceItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalPresent: data['total_present'] ?? 0,
      totalAbsent: data['total_absent'] ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'halaqah_id': halaqahId,
      'halaqah_name': halaqahName,
      'schedule_id': scheduleId,
      'date': Timestamp.fromDate(date),
      'asatidz_id': asatidzId,
      'asatidz_name': asatidzName,
      'attendance_list': attendanceList
          .map((item) => SantriAttendanceItemModel(
                santriId: item.santriId,
                santriName: item.santriName,
                status: item.status,
                notes: item.notes,
              ).toMap())
          .toList(),
      'total_present': totalPresent,
      'total_absent': totalAbsent,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
