import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';

import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';

class SantriRepositoryImpl implements SantriRepository {
  final SantriRemoteDataSource remote;
  final FirebaseFirestore firestore;

  SantriRepositoryImpl(this.remote, this.firestore);

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    final santriList = await remote.getSantriList(
      keyword: keyword,
      isActive: isActive,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    final classSnap = await firestore
        .collection('classes')
        .where('is_active', isEqualTo: true)
        .get();

    final classMap = <String, String>{};

    for (var doc in classSnap.docs) {
      final data = doc.data();
      final namaPembimbing = data['pembimbing_name'];
      // Handle potential null or type issues safely
      if (data['santri_ids'] != null) {
        final santriIds = List<String>.from(data['santri_ids']);
         for (final id in santriIds) {
          classMap[id.trim()] = namaPembimbing;
        }
      }
    }

    return santriList.map((s) {
      return SantriEntity(
        id: s.id,
        name: s.name,
        nis: s.nis,
        kelas: s.kelas,
        jenisKelamin: s.jenisKelamin,
        isActive: s.isActive,
        isFree: s.isFree,
        nomorWali: s.nomorWali,
        pembimbing: classMap[s.id.trim()] ?? 'Belum ada',
      );
    }).toList();
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async {
    final detail = await remote.getSantriDetail(id);

    // Fetch pembimbing from classes collection
    final classSnap = await firestore
        .collection('classes')
        .where('santri_ids', arrayContains: id)
        .limit(1)
        .get();

    String? namaPembimbing;
    if (classSnap.docs.isNotEmpty) {
      namaPembimbing = classSnap.docs.first.data()['pembimbing_name'];
    }

    return SantriDetail(
      id: detail.id,
      name: detail.name,
      nis: detail.nis,
      kelas: detail.kelas,
      jenisKelamin: detail.jenisKelamin,
      isActive: detail.isActive,
      isFree: detail.isFree,
      namaWali: detail.namaWali,
      nomorWali: detail.nomorWali,
      tanggalMasuk: detail.tanggalMasuk,
      tanggalLahir: detail.tanggalLahir,
      tempatLahir: detail.tempatLahir,
      tipeKelas: detail.tipeKelas,
      pembimbing: namaPembimbing ?? 'Belum ada',
      phone: detail.phone,
    );
  }

  @override
  Future<void> addSantri(SantriParams params) async {
    await remote.addSantri(params);
  }

  @override
  Future<void> updateSantri(String id, SantriParams params) async {
    await remote.updateSantri(id, params);
  }
}
