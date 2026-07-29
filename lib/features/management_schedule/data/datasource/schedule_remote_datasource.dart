import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/program_schedule_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/schedule_program_model.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/exceptions/halaqah_conflict_exception.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<ScheduleProgramModel>> getPrograms(String gender);
  Future<List<ProgramScheduleModel>> getSchedules(String programId);
  Future<ProgramScheduleModel> getScheduleById(String scheduleId);
  Future<ScheduleProgramModel> getProgramById(String programId);
  Future<List<HalaqahModel>> getHalaqahs(String programId);
  Future<List<HalaqahModel>> getHalaqahsBySchedule(String scheduleId);
  Future<List<HalaqahModel>> getHalaqahsByTeacher(String teacherId);
  Future<List<HalaqahModel>> getAllHalaqahs();
  Future<void> updateHalaqah(HalaqahModel halaqah, List<String> finalSantriIds);
  Future<void> createHalaqah(HalaqahModel halaqah, List<String> santriIds);
  Future<void> deleteHalaqah(String halaqahId);
  Future<HalaqahModel?> getHalaqahBySantriId(String santriId);
  Future<void> removeSantriFromHalaqah(String santriId);
  Future<void> moveSantriToHalaqah(
    String santriId,
    String newHalaqahId, {
    String? newSession,
  });
  Future<List<SantriEntity>> getSantrisByHalaqahId(String halaqahId);
  Future<void> migrateHalaqahIds();
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final FirebaseFirestore firestore;

  ScheduleRemoteDataSourceImpl(this.firestore);

  static const int _whereInChunkSize = 10;
  static const int _maxMembershipTransactionDocuments = 400;
  static const String _teacherSessionGuardCollection =
      'halaqah_teacher_sessions';

  @override
  Future<List<ScheduleProgramModel>> getPrograms(String gender) async {
    final query = await firestore
        .collection('sessions')
        .where('tipe', isEqualTo: gender)
        .get();
    return query.docs
        .map((doc) => ScheduleProgramModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<ScheduleProgramModel> getProgramById(String programId) async {
    final doc = await firestore.collection('sessions').doc(programId).get();
    if (!doc.exists) throw Exception('Program tidak ditemukan');
    return ScheduleProgramModel.fromFirestore(doc);
  }

  @override
  Future<List<HalaqahModel>> getHalaqahsBySchedule(String scheduleId) async {
    final snapshots = await Future.wait([
      firestore
          .collection('halaqahs')
          .where('schedule_ids', arrayContains: scheduleId)
          .get(),
      firestore
          .collection('halaqahs')
          .where('schedule_id', isEqualTo: scheduleId)
          .get(),
    ]);
    return _getHalaqahsWithCount(_uniqueDocuments(snapshots));
  }

  @override
  Future<List<ProgramScheduleModel>> getSchedules(String programId) async {
    final query = await firestore
        .collection('session_schedules')
        .where('session_id', isEqualTo: programId)
        .get();
    return query.docs
        .map((doc) => ProgramScheduleModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<HalaqahModel>> getHalaqahs(String programId) async {
    final snapshots = await Future.wait([
      firestore
          .collection('halaqahs')
          .where('session_id', isEqualTo: programId)
          .get(),
      firestore
          .collection('halaqahs')
          .where('schedule_id', isEqualTo: programId)
          .get(),
    ]);
    return _getHalaqahsWithCount(_uniqueDocuments(snapshots));
  }

  @override
  Future<void> updateHalaqah(
    HalaqahModel halaqah,
    List<String> finalSantriIds,
  ) async {
    final halaqahRef = firestore.collection('halaqahs').doc(halaqah.id);
    final sessionName = await _getCurrentSessionName(halaqah.programId);
    await _ensureTeacherSessionAvailable(
      halaqah,
      excludeHalaqahId: halaqah.id,
      sessionName: sessionName,
    );
    await _replaceMembership(
      halaqah: halaqah,
      halaqahRef: halaqahRef,
      finalSantriIds: finalSantriIds,
      sessionName: sessionName,
      isCreating: false,
    );
  }

  @override
  Future<void> createHalaqah(
    HalaqahModel halaqah,
    List<String> santriIds,
  ) async {
    final docRef = firestore.collection('halaqahs').doc();
    final sessionName = await _getCurrentSessionName(halaqah.programId);
    await _ensureTeacherSessionAvailable(halaqah, sessionName: sessionName);
    await _replaceMembership(
      halaqah: halaqah,
      halaqahRef: docRef,
      finalSantriIds: santriIds,
      sessionName: sessionName,
      isCreating: true,
    );
  }

  @override
  Future<void> deleteHalaqah(String halaqahId) async {
    // Lepaskan semua santri dari halaqah ini, lalu hapus dokumen halaqah-nya.
    final halaqahRef = firestore.collection('halaqahs').doc(halaqahId);
    final halaqahSnapshot = await halaqahRef.get();
    final santriSnapshot = await firestore
        .collection('santri_profiles')
        .where('halaqah_id', isEqualTo: halaqahId)
        .get();

    final batch = firestore.batch();
    for (final doc in santriSnapshot.docs) {
      batch.update(doc.reference, {'halaqah_id': FieldValue.delete()});
    }
    batch.delete(halaqahRef);

    if (halaqahSnapshot.exists) {
      final data = halaqahSnapshot.data() ?? const <String, dynamic>{};
      final teacherId =
          HalaqahDocumentCompat.asatidzData(data)['id']?.toString().trim() ??
          '';
      final sessionId = HalaqahDocumentCompat.sessionId(data);
      final guardRef = _teacherSessionGuardRef(teacherId, sessionId);
      if (guardRef != null) {
        final guardSnapshot = await guardRef.get();
        if (guardSnapshot.data()?['halaqah_id']?.toString() == halaqahId) {
          batch.delete(guardRef);
        }
      }
    }
    await batch.commit();
  }

  @override
  Future<ProgramScheduleModel> getScheduleById(String scheduleId) async {
    final doc = await firestore
        .collection('session_schedules')
        .doc(scheduleId)
        .get();
    if (!doc.exists) throw Exception('Jadwal tidak ditemukan');
    return ProgramScheduleModel.fromFirestore(doc);
  }

  @override
  Future<List<HalaqahModel>> getHalaqahsByTeacher(String teacherId) async {
    final query = await firestore
        .collection('halaqahs')
        .where('asatidz.id', isEqualTo: teacherId)
        .get();
    return _getHalaqahsWithCount(query.docs);
  }

  @override
  Future<List<HalaqahModel>> getAllHalaqahs() async {
    final query = await firestore.collection('halaqahs').get();
    final halaqahs = query.docs
        .map((doc) => HalaqahModel.fromFirestore(doc))
        .toList();
    return _hydrateTeacherNames(halaqahs);
  }

  @override
  Future<HalaqahModel?> getHalaqahBySantriId(String santriId) async {
    final santriDoc = await firestore
        .collection('santri_profiles')
        .doc(santriId)
        .get();
    if (!santriDoc.exists) return null;

    final halaqahId = santriDoc.data()?['halaqah_id'] as String?;
    if (halaqahId == null || halaqahId.isEmpty) return null;

    final halaqahDoc = await firestore
        .collection('halaqahs')
        .doc(halaqahId)
        .get();
    if (!halaqahDoc.exists) return null;

    final parsedHalaqah = HalaqahModel.fromFirestore(halaqahDoc);
    final halaqah = (await _hydrateTeacherNames([parsedHalaqah])).first;
    var santriCount = halaqah.santriCount;
    try {
      final countQuery = await firestore
          .collection('santri_profiles')
          .where('halaqah_id', isEqualTo: halaqah.id)
          .count()
          .get();
      santriCount = countQuery.count ?? santriCount;
    } on FirebaseException catch (error) {
      // Akun santri hanya boleh membaca profilnya sendiri, sehingga aggregate
      // seluruh anggota halaqah memang dapat ditolak rules. Nama pembimbing
      // dan detail halaqah tetap valid; gunakan cached count dokumen sebagai
      // fallback agar halaman Beranda Santri tidak ikut gagal.
      if (error.code != 'permission-denied') rethrow;
    }

    return halaqah.copyWith(santriCount: santriCount);
  }

  @override
  Future<void> removeSantriFromHalaqah(String santriId) async {
    final santriRef = firestore.collection('santri_profiles').doc(santriId);
    final santriHint = await santriRef.get();
    if (!santriHint.exists) return;

    final halaqahId = santriHint.data()?['halaqah_id']?.toString().trim() ?? '';
    if (halaqahId.isEmpty) return;

    final queriedMembers = await firestore
        .collection('santri_profiles')
        .where('halaqah_id', isEqualTo: halaqahId)
        .get();
    final queriedIds = queriedMembers.docs.map((doc) => doc.id).toSet();
    final halaqahRef = firestore.collection('halaqahs').doc(halaqahId);

    await firestore.runTransaction((transaction) async {
      final santriSnapshot = await transaction.get(santriRef);
      final halaqahSnapshot = await transaction.get(halaqahRef);
      if (!santriSnapshot.exists || !halaqahSnapshot.exists) return;

      final actualHalaqahId =
          santriSnapshot.data()?['halaqah_id']?.toString().trim() ?? '';
      if (actualHalaqahId != halaqahId) {
        throw StateError(
          'Halaqah santri telah berubah. Muat ulang sebelum menghapus.',
        );
      }

      final halaqahData = halaqahSnapshot.data() ?? const <String, dynamic>{};
      final storedIds =
          HalaqahDocumentCompat.santriIds(halaqahData) ?? queriedIds;
      final nextIds = storedIds.difference(<String>{santriId});
      final cachedCount = _intValue(halaqahData['santri_count']);

      transaction.update(santriRef, {'halaqah_id': FieldValue.delete()});
      transaction.update(halaqahRef, {
        'santri_count': cachedCount > 0 ? cachedCount - 1 : 0,
        'santri_ids': nextIds.toList(growable: false),
      });
    });

    try {
      await _refreshCachedCounts(<String>{halaqahId});
    } catch (_) {
      // Membership utama sudah committed; count adalah cache best-effort.
    }
  }

  @override
  Future<void> moveSantriToHalaqah(
    String santriId,
    String newHalaqahId, {
    String? newSession,
  }) async {
    final santriRef = firestore.collection('santri_profiles').doc(santriId);
    final santriHint = await santriRef.get();
    if (!santriHint.exists) throw Exception('Santri tidak ditemukan');

    final oldHalaqahId =
        santriHint.data()?['halaqah_id']?.toString().trim() ?? '';
    if (oldHalaqahId == newHalaqahId) return;

    Future<Set<String>> queryMemberIds(String halaqahId) async {
      if (halaqahId.isEmpty) return <String>{};
      final snapshot = await firestore
          .collection('santri_profiles')
          .where('halaqah_id', isEqualTo: halaqahId)
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    }

    final queriedIds = await Future.wait([
      queryMemberIds(oldHalaqahId),
      queryMemberIds(newHalaqahId),
    ]);
    final oldQueriedIds = queriedIds.first;
    final newQueriedIds = queriedIds.last;
    final oldHalaqahRef = oldHalaqahId.isEmpty
        ? null
        : firestore.collection('halaqahs').doc(oldHalaqahId);
    final newHalaqahRef = firestore.collection('halaqahs').doc(newHalaqahId);

    await firestore.runTransaction((transaction) async {
      final santriSnapshot = await transaction.get(santriRef);
      final oldHalaqahSnapshot = oldHalaqahRef == null
          ? null
          : await transaction.get(oldHalaqahRef);
      final newHalaqahSnapshot = await transaction.get(newHalaqahRef);
      if (!santriSnapshot.exists) {
        throw StateError('Data santri tidak ditemukan.');
      }
      if (!newHalaqahSnapshot.exists) {
        throw StateError('Halaqah tujuan tidak ditemukan.');
      }

      final actualOldHalaqahId =
          santriSnapshot.data()?['halaqah_id']?.toString().trim() ?? '';
      if (actualOldHalaqahId != oldHalaqahId) {
        throw StateError(
          'Halaqah santri telah berubah. Muat ulang sebelum memindahkan.',
        );
      }

      // Pindahkan santri sekaligus samakan tipe_kelas dengan sesi tujuan.
      final santriUpdate = <String, dynamic>{'halaqah_id': newHalaqahId};
      if (newSession != null && newSession.isNotEmpty) {
        santriUpdate['tipe_kelas'] = newSession;
      }
      transaction.update(santriRef, santriUpdate);

      if (oldHalaqahSnapshot?.exists == true) {
        final oldData = oldHalaqahSnapshot?.data() ?? const <String, dynamic>{};
        final oldIds =
            HalaqahDocumentCompat.santriIds(oldData) ?? oldQueriedIds;
        final oldCount = _intValue(oldData['santri_count']);
        transaction.update(oldHalaqahRef!, {
          'santri_count': oldCount > 0 ? oldCount - 1 : 0,
          'santri_ids': oldIds
              .difference(<String>{santriId})
              .toList(growable: false),
        });
      }

      final newData = newHalaqahSnapshot.data() ?? const <String, dynamic>{};
      final newIds = HalaqahDocumentCompat.santriIds(newData) ?? newQueriedIds;
      final newCount = _intValue(newData['santri_count']);
      transaction.update(newHalaqahRef, {
        'santri_count': newCount + 1,
        'santri_ids': <String>{...newIds, santriId}.toList(growable: false),
      });
    });

    try {
      await _refreshCachedCounts(<String>{
        if (oldHalaqahId.isNotEmpty) oldHalaqahId,
        newHalaqahId,
      });
    } catch (_) {
      // Membership utama sudah committed; count adalah cache best-effort.
    }
  }

  @override
  Future<List<SantriEntity>> getSantrisByHalaqahId(String halaqahId) async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('halaqah_id', isEqualTo: halaqahId)
        .get();

    final now = DateTime.now();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
      return SantriEntity(
        id: doc.id,
        name: data['name'] ?? '',
        nis: data['nis'] ?? '',
        kelas: data['kelas'] ?? '',
        kelasFiqih: (data['kelas_fiqih'] as String?)?.trim(),
        jenisKelamin: data['jenis_kelamin'] ?? '',
        isActive: data['is_active'] ?? true,
        isFree: freeUntil != null && freeUntil.isAfter(now),
        freeUntil: freeUntil,
        nomorWali: data['nomor_wali'],
        tipeKelas: data['tipe_kelas'],
        halaqahId: halaqahId,
        tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<void> migrateHalaqahIds() async {
    final halaqahsSnapshot = await firestore.collection('halaqahs').get();

    for (final halaqahDoc in halaqahsSnapshot.docs) {
      final data = halaqahDoc.data();
      final halaqahId = halaqahDoc.id;

      if (data['santris'] == null || data['santris'] is! List) continue;

      final santrisList = List.from(data['santris'] as List);
      if (santrisList.isEmpty) continue;

      final batch = firestore.batch();
      for (final item in santrisList) {
        if (item is! Map || item['id'] == null) continue;
        final santriId = item['id'].toString();
        final santriRef = firestore.collection('santri_profiles').doc(santriId);
        batch.update(santriRef, {'halaqah_id': halaqahId});
      }
      await batch.commit();
    }
  }

  Future<List<HalaqahModel>> _getHalaqahsWithCount(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final parsed = docs.map((doc) => HalaqahModel.fromFirestore(doc)).toList();
    final hydrated = await _hydrateTeacherNames(parsed);
    final futures = hydrated.map((halaqah) async {
      final countQuery = await firestore
          .collection('santri_profiles')
          .where('halaqah_id', isEqualTo: halaqah.id)
          .count()
          .get();
      return halaqah.copyWith(santriCount: countQuery.count ?? 0);
    });
    return Future.wait(futures);
  }

  List<DocumentSnapshot<Map<String, dynamic>>> _uniqueDocuments(
    Iterable<QuerySnapshot<Map<String, dynamic>>> snapshots,
  ) {
    final byId = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        byId[doc.id] = doc;
      }
    }
    return byId.values.toList();
  }

  Future<List<HalaqahModel>> _hydrateTeacherNames(
    List<HalaqahModel> halaqahs,
  ) async {
    if (halaqahs.isEmpty) return halaqahs;

    final teacherIds = halaqahs
        .map((halaqah) => halaqah.teacherId.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (teacherIds.isEmpty) return halaqahs;

    final currentNames = <String, String>{};
    try {
      if (teacherIds.length == 1) {
        // Direct get dapat dibuktikan aman oleh rules untuk pembimbing milik
        // santri yang sedang login. Query whereIn tetap dipakai untuk list
        // admin agar hidrasi banyak nama tidak menjadi N+1.
        final teacherId = teacherIds.single;
        final document = await firestore
            .collection('asatidz_profiles')
            .doc(teacherId)
            .get();
        final name = document.data()?['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) currentNames[teacherId] = name;
      } else {
        for (
          var index = 0;
          index < teacherIds.length;
          index += _whereInChunkSize
        ) {
          final end = (index + _whereInChunkSize).clamp(0, teacherIds.length);
          final chunk = teacherIds.sublist(index, end);
          final snapshot = await firestore
              .collection('asatidz_profiles')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final doc in snapshot.docs) {
            final name = doc.data()['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) currentNames[doc.id] = name;
          }
        }
      }
    } catch (_) {
      // Santri accounts cannot currently list asatidz_profiles. Preserve the
      // embedded legacy value so an otherwise valid Halaqah remains readable.
      return halaqahs;
    }

    return halaqahs.map((halaqah) {
      final currentName = currentNames[halaqah.teacherId];
      if (currentName == null || currentName.isEmpty) return halaqah;
      return halaqah.copyWith(teacherName: currentName);
    }).toList();
  }

  Future<String?> _getCurrentSessionName(String sessionId) async {
    final normalizedId = sessionId.trim();
    if (normalizedId.isEmpty) return null;

    final snapshot = await firestore
        .collection('sessions')
        .doc(normalizedId)
        .get();
    if (!snapshot.exists) return null;

    final rawName = snapshot.data()?['waktu']?.toString().trim() ?? '';
    if (rawName.isEmpty) return null;
    return '${rawName[0].toUpperCase()}${rawName.substring(1).toLowerCase()}';
  }

  Future<void> _ensureTeacherSessionAvailable(
    HalaqahModel halaqah, {
    String? excludeHalaqahId,
    String? sessionName,
  }) async {
    final teacherId = halaqah.teacherId.trim();
    final sessionId = halaqah.programId.trim();
    if (teacherId.isEmpty || sessionId.isEmpty) return;

    final snapshot = await firestore
        .collection('halaqahs')
        .where('asatidz.id', isEqualTo: teacherId)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == excludeHalaqahId) continue;
      if (await _referencesSession(doc.data(), sessionId)) {
        final label = sessionName?.trim().isNotEmpty == true
            ? sessionName!.trim()
            : 'yang dipilih';
        throw HalaqahConflictException(
          'Pengajar ini sudah memiliki halaqah pada sesi $label.',
        );
      }
    }
  }

  Future<bool> _referencesSession(
    Map<String, dynamic> data,
    String expectedSessionId,
  ) async {
    if (HalaqahDocumentCompat.directlyReferencesSession(
      data,
      expectedSessionId,
    )) {
      return true;
    }

    // A populated current session_id is authoritative. A legacy schedule
    // should not make a current document collide with another session.
    if (HalaqahDocumentCompat.currentSessionId(data).isNotEmpty) return false;

    final scheduleIds = HalaqahDocumentCompat.scheduleIds(data);
    if (scheduleIds.isEmpty) return false;

    final scheduleSnapshots = await Future.wait(
      scheduleIds.map(
        (scheduleId) =>
            firestore.collection('session_schedules').doc(scheduleId).get(),
      ),
    );
    return scheduleSnapshots.any(
      (snapshot) =>
          snapshot.data()?['session_id']?.toString().trim() ==
          expectedSessionId,
    );
  }

  Future<void> _replaceMembership({
    required HalaqahModel halaqah,
    required DocumentReference<Map<String, dynamic>> halaqahRef,
    required List<String> finalSantriIds,
    required String? sessionName,
    required bool isCreating,
  }) async {
    final selectedIds = finalSantriIds
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final currentMembers = isCreating
        ? null
        : await firestore
              .collection('santri_profiles')
              .where('halaqah_id', isEqualTo: halaqahRef.id)
              .get();
    final queriedCurrentIds =
        currentMembers?.docs.map((doc) => doc.id).toSet() ?? {};
    final preliminaryCandidateIds = <String>{
      ...queriedCurrentIds,
      ...selectedIds,
    };
    final newGuardRef = _teacherSessionGuardRef(
      halaqah.teacherId,
      halaqah.programId,
    );

    if (preliminaryCandidateIds.length > _maxMembershipTransactionDocuments) {
      throw StateError(
        'Jumlah santri terlalu banyak untuk diproses sekaligus. '
        'Kurangi pilihan lalu coba kembali.',
      );
    }

    final affectedHalaqahIds = await firestore.runTransaction<Set<String>>((
      transaction,
    ) async {
      DocumentSnapshot<Map<String, dynamic>>? currentHalaqahSnapshot;
      if (!isCreating) {
        currentHalaqahSnapshot = await transaction.get(halaqahRef);
        if (!currentHalaqahSnapshot.exists) {
          throw StateError('Data halaqah tidak ditemukan.');
        }
      }

      final currentHalaqahData =
          currentHalaqahSnapshot?.data() ?? const <String, dynamic>{};
      final transactionCurrentIds =
          HalaqahDocumentCompat.santriIds(currentHalaqahData) ??
          queriedCurrentIds;
      final candidateIds = <String>{...transactionCurrentIds, ...selectedIds};
      if (candidateIds.length > _maxMembershipTransactionDocuments) {
        throw StateError(
          'Jumlah santri terlalu banyak untuk diproses sekaligus.',
        );
      }

      DocumentSnapshot<Map<String, dynamic>>? newGuardSnapshot;
      DocumentSnapshot<Map<String, dynamic>>? guardedHalaqahSnapshot;
      if (newGuardRef != null) {
        newGuardSnapshot = await transaction.get(newGuardRef);
        final guardedHalaqahId =
            newGuardSnapshot.data()?['halaqah_id']?.toString().trim() ?? '';
        if (guardedHalaqahId.isNotEmpty && guardedHalaqahId != halaqahRef.id) {
          guardedHalaqahSnapshot = await transaction.get(
            firestore.collection('halaqahs').doc(guardedHalaqahId),
          );
        }
      }

      DocumentReference<Map<String, dynamic>>? previousGuardRef;
      DocumentSnapshot<Map<String, dynamic>>? previousGuardSnapshot;
      if (currentHalaqahSnapshot?.exists == true) {
        final currentData =
            currentHalaqahSnapshot?.data() ?? const <String, dynamic>{};
        final currentTeacherId =
            HalaqahDocumentCompat.asatidzData(
              currentData,
            )['id']?.toString().trim() ??
            '';
        final currentSessionId = HalaqahDocumentCompat.sessionId(currentData);
        final candidatePreviousRef = _teacherSessionGuardRef(
          currentTeacherId,
          currentSessionId,
        );
        if (candidatePreviousRef != null &&
            candidatePreviousRef.path != newGuardRef?.path) {
          previousGuardRef = candidatePreviousRef;
          previousGuardSnapshot = await transaction.get(candidatePreviousRef);
        }
      }

      final santriSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final santriId in candidateIds) {
        final santriRef = firestore.collection('santri_profiles').doc(santriId);
        santriSnapshots[santriId] = await transaction.get(santriRef);
      }

      for (final santriId in selectedIds) {
        if (santriSnapshots[santriId]?.exists != true) {
          throw StateError('Data santri tidak ditemukan.');
        }
      }

      final movedIdsByOldHalaqah = <String, Set<String>>{};
      for (final santriId in selectedIds) {
        final oldHalaqahId =
            santriSnapshots[santriId]
                ?.data()?['halaqah_id']
                ?.toString()
                .trim() ??
            '';
        if (oldHalaqahId.isEmpty || oldHalaqahId == halaqahRef.id) continue;
        movedIdsByOldHalaqah.update(
          oldHalaqahId,
          (ids) => ids..add(santriId),
          ifAbsent: () => <String>{santriId},
        );
      }

      final estimatedWrites =
          candidateIds.length + movedIdsByOldHalaqah.length + 1;
      if (estimatedWrites > _maxMembershipTransactionDocuments) {
        throw StateError(
          'Perpindahan santri terlalu banyak untuk diproses sekaligus.',
        );
      }

      final oldHalaqahSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final oldHalaqahId in movedIdsByOldHalaqah.keys) {
        final oldRef = firestore.collection('halaqahs').doc(oldHalaqahId);
        oldHalaqahSnapshots[oldHalaqahId] = await transaction.get(oldRef);
      }

      final guardedHalaqahId =
          newGuardSnapshot?.data()?['halaqah_id']?.toString().trim() ?? '';
      if (guardedHalaqahId.isNotEmpty &&
          guardedHalaqahId != halaqahRef.id &&
          guardedHalaqahSnapshot?.exists == true) {
        final label = sessionName?.trim().isNotEmpty == true
            ? sessionName!.trim()
            : 'yang dipilih';
        throw HalaqahConflictException(
          'Pengajar ini sudah memiliki halaqah pada sesi $label.',
        );
      }

      for (final entry in santriSnapshots.entries) {
        final santriId = entry.key;
        final santriSnapshot = entry.value;
        if (!santriSnapshot.exists) continue;

        final santriRef = firestore.collection('santri_profiles').doc(santriId);
        final assignedHalaqahId =
            santriSnapshot.data()?['halaqah_id']?.toString().trim() ?? '';

        if (selectedIds.contains(santriId)) {
          final update = <String, dynamic>{'halaqah_id': halaqahRef.id};
          if (sessionName != null && sessionName.isNotEmpty) {
            update['tipe_kelas'] = sessionName;
          }
          transaction.update(santriRef, update);
        } else if (assignedHalaqahId == halaqahRef.id) {
          // Do not erase an assignment that changed after the edit screen was
          // opened. The transaction only clears members still owned by target.
          transaction.update(santriRef, {'halaqah_id': FieldValue.delete()});
        }
      }

      for (final entry in movedIdsByOldHalaqah.entries) {
        final oldSnapshot = oldHalaqahSnapshots[entry.key];
        if (oldSnapshot?.exists != true) continue;

        final rawCount = oldSnapshot?.data()?['santri_count'];
        final cachedCount = rawCount is num
            ? rawCount.toInt()
            : int.tryParse(rawCount?.toString() ?? '') ?? 0;
        final nextCount = cachedCount > entry.value.length
            ? cachedCount - entry.value.length
            : 0;
        final oldUpdate = <String, dynamic>{'santri_count': nextCount};
        final oldSantriIds = HalaqahDocumentCompat.santriIds(
          oldSnapshot!.data() ?? const <String, dynamic>{},
        );
        if (oldSantriIds != null) {
          oldUpdate['santri_ids'] = oldSantriIds
              .difference(entry.value)
              .toList(growable: false);
        }
        transaction.update(oldSnapshot.reference, oldUpdate);
      }

      final halaqahData = halaqah.toCurrentFirestore(
        santriCount: selectedIds.length,
        santriIds: selectedIds,
      );
      if (isCreating) {
        transaction.set(halaqahRef, halaqahData);
      } else {
        transaction.update(halaqahRef, halaqahData);
      }

      if (previousGuardRef != null &&
          previousGuardSnapshot?.data()?['halaqah_id']?.toString() ==
              halaqahRef.id) {
        transaction.delete(previousGuardRef);
      }
      if (newGuardRef != null) {
        transaction.set(newGuardRef, <String, dynamic>{
          'teacher_id': halaqah.teacherId,
          'session_id': halaqah.programId,
          'halaqah_id': halaqahRef.id,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      return <String>{halaqahRef.id, ...movedIdsByOldHalaqah.keys};
    });

    try {
      await _refreshCachedCounts(affectedHalaqahIds);
    } catch (_) {
      // Membership di atas sudah committed secara atomik. santri_count hanya
      // cache tampilan dan juga dihitung ulang saat list dibaca, jadi kegagalan
      // refresh tidak boleh membuat UI menganggap create/edit utama gagal lalu
      // mengulang operasi yang sebenarnya sudah berhasil.
    }
  }

  DocumentReference<Map<String, dynamic>>? _teacherSessionGuardRef(
    String teacherId,
    String sessionId,
  ) {
    final normalizedTeacherId = teacherId.trim();
    final normalizedSessionId = sessionId.trim();
    if (normalizedTeacherId.isEmpty || normalizedSessionId.isEmpty) return null;

    final guardId = Uri.encodeComponent(
      '$normalizedTeacherId::$normalizedSessionId',
    );
    return firestore.collection(_teacherSessionGuardCollection).doc(guardId);
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _refreshCachedCounts(Set<String> halaqahIds) async {
    if (halaqahIds.isEmpty) return;

    var batch = firestore.batch();
    var pendingWrites = 0;

    for (final halaqahId in halaqahIds) {
      final halaqahRef = firestore.collection('halaqahs').doc(halaqahId);
      final halaqahSnapshot = await halaqahRef.get();
      if (!halaqahSnapshot.exists) continue;

      final countSnapshot = await firestore
          .collection('santri_profiles')
          .where('halaqah_id', isEqualTo: halaqahId)
          .count()
          .get();
      batch.update(halaqahRef, {'santri_count': countSnapshot.count ?? 0});
      pendingWrites++;

      if (pendingWrites >= _maxMembershipTransactionDocuments) {
        await batch.commit();
        batch = firestore.batch();
        pendingWrites = 0;
      }
    }

    if (pendingWrites > 0) await batch.commit();
  }
}
