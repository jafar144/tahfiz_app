import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/meeting_member.dart';

class MeetingMemberModel extends MeetingMember {
  MeetingMemberModel({
    required super.id,
    required super.santriId,
    required super.santriName,
    required super.halaqahAsalId,
    required super.attendanceStatus,
    super.setoranValue,
    super.setoranNotes,
    required super.createdAt,
  });

  factory MeetingMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingMemberModel(
      id: doc.id,
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      halaqahAsalId: data['halaqah_asal_id'] ?? '',
      attendanceStatus: data['attendance_status'] ?? 'hadir',
      setoranValue: data['setoran_value'],
      setoranNotes: data['setoran_notes'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santri_id': santriId,
      'santri_name': santriName,
      'halaqah_asal_id': halaqahAsalId,
      'attendance_status': attendanceStatus,
      if (setoranValue != null) 'setoran_value': setoranValue,
      if (setoranNotes != null) 'setoran_notes': setoranNotes,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
