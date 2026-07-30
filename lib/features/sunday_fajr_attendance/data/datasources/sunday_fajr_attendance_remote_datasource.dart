import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/data/models/sunday_fajr_attendance_model.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/data/models/sunday_fajr_participant_model.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_eligibility.dart';

abstract class SundayFajrAttendanceRemoteDataSource {
  Future<List<SundayFajrAttendanceModel>> getAttendanceHistory({
    int limit = 52,
  });

  Future<SundayFajrAttendanceModel?> getAttendance(String weekKey);

  Future<List<SundayFajrParticipantModel>> getParticipants(String weekKey);

  Future<List<SantriEntity>> getEligibleSantri();

  Future<SundayFajrAttendanceModel> saveAttendance({
    required DateTime eventDate,
    required List<SundayFajrParticipant> participants,
    required String actorId,
    required int expectedRevision,
  });

  Future<List<SundayFajrParticipantModel>> getSantriHistory(
    String santriId, {
    int limit = 52,
  });

  Future<SundayFajrParticipantModel?> getLatestSantriAttendance(
    String santriId,
  );
}

class SundayFajrAttendanceRemoteDataSourceImpl
    implements SundayFajrAttendanceRemoteDataSource {
  SundayFajrAttendanceRemoteDataSourceImpl(this.firestore);

  final FirebaseFirestore firestore;

  static const collectionName = 'sunday_fajr_attendance';
  static const participantCollectionName = 'participants';
  static const participantRecordType = 'sunday_fajr_participant';
  static const maxParticipantsPerWrite =
      SundayFajrAttendancePolicy.maxParticipantsPerSave;

  CollectionReference<Map<String, dynamic>> get _attendanceCollection =>
      firestore.collection(collectionName);

  @override
  Future<List<SundayFajrAttendanceModel>> getAttendanceHistory({
    int limit = 52,
  }) async {
    final snapshot = await _attendanceCollection
        .orderBy('event_date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(SundayFajrAttendanceModel.fromFirestore).toList();
  }

  @override
  Future<SundayFajrAttendanceModel?> getAttendance(String weekKey) async {
    final document = await _attendanceCollection.doc(weekKey).get();
    if (!document.exists) return null;
    return SundayFajrAttendanceModel.fromFirestore(document);
  }

  @override
  Future<List<SundayFajrParticipantModel>> getParticipants(
    String weekKey,
  ) async {
    final snapshot = await _attendanceCollection
        .doc(weekKey)
        .collection(participantCollectionName)
        .orderBy('santri_name')
        .get();
    return snapshot.docs.map(SundayFajrParticipantModel.fromFirestore).toList();
  }

  @override
  Future<List<SantriEntity>> getEligibleSantri() async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('jenis_kelamin', isEqualTo: 'L')
        .orderBy('name')
        .get();

    // Dokumen santri versi lama dapat belum memiliki is_active. Parser
    // memperlakukannya aktif (sejalan dengan fitur santri lain), lalu filter
    // eligibility dilakukan di client agar roster tetap backward-compatible.
    final result = snapshot.docs
        .map(_santriFromDocument)
        .where(isSundayFajrEligibleSantri)
        .toList();
    result.sort(_compareSantri);
    return result;
  }

  @override
  Future<SundayFajrAttendanceModel> saveAttendance({
    required DateTime eventDate,
    required List<SundayFajrParticipant> participants,
    required String actorId,
    required int expectedRevision,
  }) async {
    final canonicalDate = SundayFajrAttendancePolicy.canonicalDate(eventDate);
    if (!SundayFajrAttendancePolicy.isEditable(canonicalDate)) {
      throw const SundayFajrLockedException();
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('Identitas admin tidak valid.');
    }
    if (!SundayFajrAttendancePolicy.isRosterSizeSupported(
      participants.length,
    )) {
      throw const SundayFajrRosterTooLargeException();
    }

    final weekKey = SundayFajrAttendancePolicy.weekKey(canonicalDate);
    final attendanceReference = _attendanceCollection.doc(weekKey);
    final participantIds = participants.map((item) => item.santriId).toSet();
    if (participantIds.length != participants.length) {
      throw ArgumentError('Daftar peserta mengandung santri duplikat.');
    }

    final existingHint = await attendanceReference.get();
    Set<String>? storedRosterIds;
    Set<String>? eligibleRosterIds;
    if (existingHint.exists) {
      final existingParticipants = await attendanceReference
          .collection(participantCollectionName)
          .get();
      storedRosterIds = existingParticipants.docs.map((doc) => doc.id).toSet();
      if (storedRosterIds.length != participantIds.length ||
          !storedRosterIds.containsAll(participantIds)) {
        throw StateError(
          'Roster absensi yang sudah tersimpan tidak boleh diubah.',
        );
      }
    } else {
      if (!SundayFajrAttendancePolicy.canCreate(canonicalDate)) {
        throw const SundayFajrLockedException();
      }
      eligibleRosterIds = (await getEligibleSantri())
          .map((santri) => santri.id)
          .toSet();
      if (eligibleRosterIds.length != participantIds.length ||
          !eligibleRosterIds.containsAll(participantIds)) {
        throw StateError(
          'Daftar santri wajib telah berubah. Muat ulang sebelum menyimpan.',
        );
      }
    }

    final normalizedParticipants = participants.map((participant) {
      if (participant.santriId.trim().isEmpty ||
          participant.santriName.trim().isEmpty ||
          participant.kelas.trim().isEmpty) {
        throw ArgumentError('Data identitas peserta belum lengkap.');
      }
      return participant.copyWith(izinReason: '');
    }).toList();

    final totalHadir = normalizedParticipants
        .where((item) => item.status == SundayFajrAttendanceStatus.hadir)
        .length;
    final totalIzin = normalizedParticipants
        .where((item) => item.status == SundayFajrAttendanceStatus.izin)
        .length;
    final totalAlpha = normalizedParticipants
        .where((item) => item.status == SundayFajrAttendanceStatus.alpha)
        .length;

    return firestore.runTransaction<SundayFajrAttendanceModel>((
      transaction,
    ) async {
      final document = await transaction.get(attendanceReference);
      final existing = document.exists
          ? SundayFajrAttendanceModel.fromFirestore(document)
          : null;
      final currentRevision = existing?.revision ?? 0;
      if (currentRevision != expectedRevision) {
        throw const SundayFajrRevisionConflictException();
      }
      if (existing == null) {
        if (!SundayFajrAttendancePolicy.canCreate(canonicalDate) ||
            eligibleRosterIds == null ||
            eligibleRosterIds.length != participantIds.length ||
            !eligibleRosterIds.containsAll(participantIds)) {
          throw const SundayFajrLockedException();
        }
      } else {
        if (!SundayFajrAttendancePolicy.isEditable(canonicalDate)) {
          throw const SundayFajrLockedException();
        }
        if (storedRosterIds == null ||
            storedRosterIds.length != participantIds.length ||
            !storedRosterIds.containsAll(participantIds) ||
            existing.participantCount != participantIds.length) {
          throw StateError(
            'Roster absensi yang sudah tersimpan tidak boleh diubah.',
          );
        }
      }

      final nextRevision = currentRevision + 1;
      if (existing == null) {
        transaction.set(attendanceReference, {
          'week_key': weekKey,
          'event_date': Timestamp.fromDate(canonicalDate),
          'participant_count': normalizedParticipants.length,
          'total_hadir': totalHadir,
          'total_izin': totalIzin,
          'total_alpha': totalAlpha,
          'revision': nextRevision,
          'schema_version': 1,
          'created_by': actorId,
          'created_at': FieldValue.serverTimestamp(),
          'updated_by': actorId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(attendanceReference, {
          'total_hadir': totalHadir,
          'total_izin': totalIzin,
          'total_alpha': totalAlpha,
          'revision': nextRevision,
          'updated_by': actorId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      for (final participant in normalizedParticipants) {
        final reference = attendanceReference
            .collection(participantCollectionName)
            .doc(participant.santriId);
        if (existing == null) {
          transaction.set(reference, {
            'record_type': participantRecordType,
            'santri_id': participant.santriId,
            'santri_name': participant.santriName,
            'santri_nis': participant.santriNis,
            'kelas': participant.kelas,
            'week_key': weekKey,
            'event_date': Timestamp.fromDate(canonicalDate),
            'status': participant.status.value,
            'izin_reason': participant.izinReason,
          });
        } else {
          transaction.update(reference, {
            'status': participant.status.value,
            'izin_reason': participant.izinReason,
          });
        }
      }

      final now = DateTime.now();
      return SundayFajrAttendanceModel(
        id: weekKey,
        weekKey: weekKey,
        eventDate: canonicalDate,
        participantCount: normalizedParticipants.length,
        totalHadir: totalHadir,
        totalIzin: totalIzin,
        totalAlpha: totalAlpha,
        revision: nextRevision,
        schemaVersion: 1,
        createdBy: existing?.createdBy ?? actorId,
        createdAt: existing?.createdAt ?? now,
        updatedBy: actorId,
        updatedAt: now,
      );
    });
  }

  @override
  Future<List<SundayFajrParticipantModel>> getSantriHistory(
    String santriId, {
    int limit = 52,
  }) async {
    final snapshot = await firestore
        .collectionGroup(participantCollectionName)
        .where('record_type', isEqualTo: participantRecordType)
        .where('santri_id', isEqualTo: santriId)
        .orderBy('event_date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(SundayFajrParticipantModel.fromFirestore).toList();
  }

  @override
  Future<SundayFajrParticipantModel?> getLatestSantriAttendance(
    String santriId,
  ) async {
    final history = await getSantriHistory(santriId, limit: 1);
    return history.firstOrNull;
  }

  static SantriEntity _santriFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
    final isFree =
        freeUntil?.isAfter(DateTime.now()) ?? (data['is_free'] == true);
    return SantriEntity(
      id: document.id,
      name: data['name'] as String? ?? '',
      nis: data['nis']?.toString() ?? '',
      kelas: data['kelas'] as String? ?? '',
      kelasFiqih: data['kelas_fiqih'] as String?,
      jenisKelamin: data['jenis_kelamin'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      isFree: isFree,
      freeUntil: freeUntil,
      nomorWali: data['nomor_wali'] as String?,
      tipeKelas: data['tipe_kelas'] as String?,
      halaqahId: data['halaqah_id'] as String?,
      tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      photoUrl: data['photo_url'] as String?,
    );
  }

  static int _compareSantri(SantriEntity first, SantriEntity second) {
    final firstNis = int.tryParse(first.nis);
    final secondNis = int.tryParse(second.nis);
    if (firstNis != null && secondNis != null) {
      final comparison = firstNis.compareTo(secondNis);
      if (comparison != 0) return comparison;
    } else {
      final comparison = first.nis.compareTo(second.nis);
      if (comparison != 0) return comparison;
    }
    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }
}
