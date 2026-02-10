import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';

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
    required super.santris,
  });

  factory HalaqahModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final asatidz = data['asatidz'] as Map<String, dynamic>? ?? {};
    final santrisList = (data['santris'] as List<dynamic>? ?? [])
        .map((e) => HalaqahSantriModel.fromJson(e as Map<String, dynamic>))
        .toList();
    
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
      santris: santrisList,
    );
  }
}

class HalaqahSantriModel extends HalaqahSantri {
  const HalaqahSantriModel({
    required super.id,
    required super.name,
    required super.nis,
  });

  factory HalaqahSantriModel.fromJson(Map<String, dynamic> json) {
    return HalaqahSantriModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nis: json['nis'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nis': nis,
    };
  }
}
