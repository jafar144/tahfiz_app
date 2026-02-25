import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';

class HalaqahModel extends Halaqah {
  const HalaqahModel({
    required super.id,
    required super.programId,
    required super.scheduleIds,
    required super.name,
    required super.room,
    required super.teacherId,
    required super.teacherName,
    required super.status,
    super.santriCount = 0,
  });

  factory HalaqahModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final asatidz = data['asatidz'] as Map<String, dynamic>? ?? {};

    List<String> scheduleIds;
    if (data['schedule_ids'] != null) {
      scheduleIds = List<String>.from(data['schedule_ids']);
    } else if (data['schedule_id'] != null) {
      scheduleIds = [data['schedule_id'] as String];
    } else {
      scheduleIds = [];
    }

    return HalaqahModel(
      id: doc.id,
      programId: data['session_id'] ?? '',
      scheduleIds: scheduleIds,
      name: data['name'] ?? '',
      room: data['room'] ?? '',
      teacherId: asatidz['id'] ?? '',
      teacherName: asatidz['name'] ?? '',
      status: data['status'] ?? 'Active',
      santriCount: data['santri_count'] ?? 0,
    );
  }
}
