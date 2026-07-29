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
    final asatidz = HalaqahDocumentCompat.asatidzData(data);

    return HalaqahModel(
      id: doc.id,
      programId: HalaqahDocumentCompat.sessionId(data),
      scheduleIds: HalaqahDocumentCompat.scheduleIds(data),
      name: data['name']?.toString() ?? '',
      room: data['room']?.toString() ?? '',
      teacherId: asatidz['id']?.toString() ?? '',
      teacherName: asatidz['name']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Active',
      santriCount: _intValue(data['santri_count']),
    );
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  HalaqahModel copyWith({String? teacherName, int? santriCount}) {
    return HalaqahModel(
      id: id,
      programId: programId,
      scheduleIds: scheduleIds,
      name: name,
      room: room,
      teacherId: teacherId,
      teacherName: teacherName ?? this.teacherName,
      status: status,
      santriCount: santriCount ?? this.santriCount,
    );
  }

  Map<String, dynamic> toCurrentFirestore({
    required int santriCount,
    Iterable<String>? santriIds,
  }) {
    return <String, dynamic>{
      // `name` remains writable so older app versions and documents keep
      // working, although the current UI no longer asks users to edit it.
      'name': name,
      'room': room,
      'schedule_ids': scheduleIds,
      'session_id': programId,
      'status': status,
      // Never persist a display name for new writes. It is hydrated from the
      // canonical asatidz_profiles document when Halaqah data is read.
      'asatidz': <String, dynamic>{'id': teacherId},
      'santri_count': santriCount,
      if (santriIds != null) 'santri_ids': santriIds.toList(growable: false),
    };
  }
}

/// Pure compatibility helpers for current and legacy Halaqah documents.
///
/// Older documents may use a singular `schedule_id` in place of
/// `schedule_ids`, and some very old documents used that field as the session
/// reference. Keeping the compatibility logic in one place prevents reads and
/// duplicate validation from interpreting the same document differently.
class HalaqahDocumentCompat {
  const HalaqahDocumentCompat._();

  static Map<String, dynamic> asatidzData(Map<String, dynamic> data) {
    final raw = data['asatidz'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  static String sessionId(Map<String, dynamic> data) {
    final current = currentSessionId(data);
    if (current.isNotEmpty) return current;

    // Sebagian dokumen sangat lama menyimpan ID sesi pada `schedule_id`.
    // Fallback ini menjaga dokumen tersebut tetap muncul pada UI versi baru.
    return data['schedule_id']?.toString().trim() ?? '';
  }

  static String currentSessionId(Map<String, dynamic> data) {
    final value = data['session_id'];
    return value is String ? value.trim() : '';
  }

  static List<String> scheduleIds(Map<String, dynamic> data) {
    final current = data['schedule_ids'];
    if (current is Iterable) {
      return current
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    final legacy = data['schedule_id']?.toString().trim() ?? '';
    return legacy.isEmpty ? const <String>[] : <String>[legacy];
  }

  /// Null berarti dokumen lama belum memiliki snapshot anggota otoritatif.
  /// List kosong tetap berbeda dari null: itu adalah snapshot valid tanpa
  /// anggota dan harus dipakai saat transaction retry.
  static Set<String>? santriIds(Map<String, dynamic> data) {
    if (!data.containsKey('santri_ids')) return null;
    final raw = data['santri_ids'];
    if (raw is! Iterable) return null;
    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static bool directlyReferencesSession(
    Map<String, dynamic> data,
    String expectedSessionId,
  ) {
    final normalizedExpected = expectedSessionId.trim();
    if (normalizedExpected.isEmpty) return false;

    final current = currentSessionId(data);
    if (current.isNotEmpty) {
      return current == normalizedExpected;
    }

    // Legacy schema used schedule_id as a session alias.
    final legacyScheduleId = data['schedule_id']?.toString().trim() ?? '';
    return legacyScheduleId == normalizedExpected;
  }
}
