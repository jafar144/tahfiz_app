import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';

class SantriRepositoryImpl implements SantriRepository {
  final SantriRemoteDataSource remote;
  final FirebaseFirestore firestore;

  SantriRepositoryImpl(this.remote, this.firestore);

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
      sortBy: sortBy,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    // Ambil semua halaqah aktif, buat map halaqahId -> teacherName
    final halaqahSnap = await firestore
        .collection('halaqahs')
        .where('status', isEqualTo: 'Active')
        .get();

    final halaqahTeacherMap = <String, String>{};
    for (var doc in halaqahSnap.docs) {
      final data = doc.data();
      final asatidzData = data['asatidz'] as Map<String, dynamic>?;
      final teacherName = asatidzData?['name'] as String?;
      if (teacherName != null) {
        halaqahTeacherMap[doc.id] = teacherName;
      }
    }

    return santriList.map((s) {
      final pembimbing = s.halaqahId != null
          ? halaqahTeacherMap[s.halaqahId]
          : null;
      return SantriEntity(
        id: s.id,
        name: s.name,
        nis: s.nis,
        kelas: s.kelas,
        kelasFiqih: s.kelasFiqih,
        jenisKelamin: s.jenisKelamin,
        isActive: s.isActive,
        isFree: s.isFree,
        freeUntil: s.freeUntil,
        nomorWali: s.nomorWali,
        tipeKelas: s.tipeKelas,
        tanggalMasuk: s.tanggalMasuk,
        halaqahId: s.halaqahId,
        halaqahName: s.halaqahName,
        pembimbing: pembimbing ?? 'Belum ada',
        photoUrl: s.photoUrl,
      );
    }).toList();
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
        final asatidz = halaqahDoc.data()?['asatidz'] as Map<String, dynamic>?;
        namaPembimbing = asatidz?['name'];
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

    // Ambil halaqah aktif, buat map halaqahId -> teacherName
    final halaqahSnap = await firestore
        .collection('halaqahs')
        .where('status', isEqualTo: 'Active')
        .get();

    final halaqahTeacherMap = <String, String>{};
    for (var doc in halaqahSnap.docs) {
      final data = doc.data();
      final asatidzData = data['asatidz'] as Map<String, dynamic>?;
      final teacherName = asatidzData?['name'] as String?;
      if (teacherName != null) {
        halaqahTeacherMap[doc.id] = teacherName;
      }
    }

    return santriList.map((s) {
      final pembimbing = s.halaqahId != null
          ? halaqahTeacherMap[s.halaqahId]
          : null;
      return SantriEntity(
        id: s.id,
        name: s.name,
        nis: s.nis,
        kelas: s.kelas,
        kelasFiqih: s.kelasFiqih,
        jenisKelamin: s.jenisKelamin,
        isActive: s.isActive,
        isFree: s.isFree,
        freeUntil: s.freeUntil,
        nomorWali: s.nomorWali,
        tipeKelas: s.tipeKelas,
        tanggalMasuk: s.tanggalMasuk,
        halaqahId: s.halaqahId,
        halaqahName: s.halaqahName,
        pembimbing: pembimbing ?? 'Belum ada',
        photoUrl: s.photoUrl,
      );
    }).toList();
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async {
    return await remote.getAsatidzList();
  }
}
