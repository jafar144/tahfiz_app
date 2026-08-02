import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_page_result.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';

class SantriRepositoryImpl implements SantriRepository {
  final SantriRemoteDataSource remote;
  final FirebaseFirestore firestore;

  SantriRepositoryImpl(this.remote, this.firestore);

  @override
  Future<SantriPageResult> getSantriPage({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    bool? hasGuardianPhone,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
  }) async {
    final page = await remote.getSantriPage(
      keyword: keyword,
      isActive: isActive,
      gender: gender,
      session: session,
      kelas: kelas,
      asatidzId: asatidzId,
      isFree: isFree,
      hasPhoto: hasPhoto,
      hasHalaqah: hasHalaqah,
      hasGuardianPhone: hasGuardianPhone,
      sortBy: sortBy,
      limit: limit,
    );
    return SantriPageResult(
      items: await _withCurrentTeacherNames(page.items),
      totalCount: page.totalCount,
    );
  }

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    bool? hasGuardianPhone,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    final santriList = await remote.getSantriList(
      keyword: keyword,
      isActive: isActive,
      gender: gender,
      session: session,
      kelas: kelas,
      asatidzId: asatidzId,
      isFree: isFree,
      hasPhoto: hasPhoto,
      hasHalaqah: hasHalaqah,
      hasGuardianPhone: hasGuardianPhone,
      sortBy: sortBy,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    return _withCurrentTeacherNames(santriList);
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async {
    final detail = await remote.getSantriDetail(id);

    String? namaPembimbing;
    if (detail.halaqahId != null) {
      final halaqahDoc = await firestore
          .collection('halaqahs')
          .doc(detail.halaqahId)
          .get();
      if (halaqahDoc.exists) {
        final asatidz = _asatidzData(halaqahDoc.data());
        final teacherId = asatidz['id']?.toString().trim() ?? '';
        final currentNames = await _getCurrentAsatidzNames(
          teacherId.isEmpty ? const <String>{} : <String>{teacherId},
        );
        namaPembimbing =
            currentNames[teacherId] ?? asatidz['name']?.toString().trim();
      }
    }

    return SantriDetail(
      id: detail.id,
      name: detail.name,
      nis: detail.nis,
      kelas: detail.kelas,
      kelasFiqih: detail.kelasFiqih,
      jenisKelamin: detail.jenisKelamin,
      isActive: detail.isActive,
      isFree: detail.isFree,
      freeUntil: detail.freeUntil,
      namaWali: detail.namaWali,
      nomorWali: detail.nomorWali,
      tanggalMasuk: detail.tanggalMasuk,
      tanggalLahir: detail.tanggalLahir,
      tempatLahir: detail.tempatLahir,
      tipeKelas: detail.tipeKelas,
      pembimbing: namaPembimbing ?? 'Belum ada',
      phone: detail.phone,
      halaqahId: detail.halaqahId,
      halaqahName: detail.halaqahName,
      photoUrl: detail.photoUrl,
    );
  }

  @override
  Future<String> addSantri(SantriParams params) => remote.addSantri(params);

  @override
  Future<String> getNextNis() => remote.getNextNis();

  @override
  Future<bool> isNisTaken(String nis) => remote.isNisTaken(nis);

  @override
  Future<void> updateSantri(String id, SantriParams params) async {
    await remote.updateSantri(id, params);
  }

  @override
  Future<List<SantriEntity>> getSantriByIds(List<String> ids) async {
    final santriList = await remote.getSantriByIds(ids);

    return _withCurrentTeacherNames(santriList);
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async {
    return await remote.getAsatidzList();
  }

  Future<List<SantriEntity>> _withCurrentTeacherNames(
    List<SantriEntity> santriList,
  ) async {
    if (santriList.isEmpty) return santriList;

    final halaqahIds = santriList
        .map((santri) => santri.halaqahId?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final halaqahTeacherMap = await _getCurrentTeacherNamesByHalaqah(
      halaqahIds,
    );
    return santriList.map((santri) {
      final pembimbing = santri.halaqahId != null
          ? halaqahTeacherMap[santri.halaqahId]
          : null;
      return SantriEntity(
        id: santri.id,
        name: santri.name,
        nis: santri.nis,
        kelas: santri.kelas,
        kelasFiqih: santri.kelasFiqih,
        jenisKelamin: santri.jenisKelamin,
        isActive: santri.isActive,
        isFree: santri.isFree,
        freeUntil: santri.freeUntil,
        nomorWali: santri.nomorWali,
        tipeKelas: santri.tipeKelas,
        tanggalMasuk: santri.tanggalMasuk,
        halaqahId: santri.halaqahId,
        halaqahName: santri.halaqahName,
        pembimbing: pembimbing ?? 'Belum ada',
        photoUrl: santri.photoUrl,
      );
    }).toList();
  }

  Future<Map<String, String>> _getCurrentTeacherNamesByHalaqah(
    Set<String> halaqahIds,
  ) async {
    if (halaqahIds.isEmpty) return const <String, String>{};

    final halaqahDocuments = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final ids = halaqahIds.toList();
    for (var index = 0; index < ids.length; index += 10) {
      final end = index + 10 < ids.length ? index + 10 : ids.length;
      final snapshot = await firestore
          .collection('halaqahs')
          .where(FieldPath.documentId, whereIn: ids.sublist(index, end))
          .get();
      halaqahDocuments.addAll(snapshot.docs);
    }

    final teacherIdByHalaqah = <String, String>{};
    final embeddedNameByHalaqah = <String, String>{};
    final teacherIds = <String>{};

    for (final doc in halaqahDocuments) {
      final asatidz = _asatidzData(doc.data());
      final teacherId = asatidz['id']?.toString().trim() ?? '';
      final embeddedName = asatidz['name']?.toString().trim() ?? '';

      if (teacherId.isNotEmpty) {
        teacherIdByHalaqah[doc.id] = teacherId;
        teacherIds.add(teacherId);
      }
      if (embeddedName.isNotEmpty) {
        embeddedNameByHalaqah[doc.id] = embeddedName;
      }
    }

    final currentNames = await _getCurrentAsatidzNames(teacherIds);
    final result = <String, String>{};
    for (final doc in halaqahDocuments) {
      final name =
          currentNames[teacherIdByHalaqah[doc.id]] ??
          embeddedNameByHalaqah[doc.id];
      if (name != null && name.isNotEmpty) result[doc.id] = name;
    }
    return result;
  }

  Future<Map<String, String>> _getCurrentAsatidzNames(
    Set<String> teacherIds,
  ) async {
    if (teacherIds.isEmpty) return const <String, String>{};

    final ids = teacherIds.toList();
    final names = <String, String>{};
    try {
      for (var index = 0; index < ids.length; index += 10) {
        final end = index + 10 < ids.length ? index + 10 : ids.length;
        final snapshot = await firestore
            .collection('asatidz_profiles')
            .where(FieldPath.documentId, whereIn: ids.sublist(index, end))
            .get();
        for (final doc in snapshot.docs) {
          final name = doc.data()['name']?.toString().trim() ?? '';
          if (name.isNotEmpty) names[doc.id] = name;
        }
      }
    } catch (_) {
      // Keep the embedded Halaqah name as a backward-compatible fallback.
    }
    return names;
  }

  static Map<String, dynamic> _asatidzData(Map<String, dynamic>? halaqahData) {
    final raw = halaqahData?['asatidz'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }
}
