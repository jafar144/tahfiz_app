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
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    final halaqahSnap = await firestore
        .collection('halaqahs')
        .where('status', isEqualTo: 'Active')
        .get();

    final classMap = <String, String>{};

    for (var doc in halaqahSnap.docs) {
      final data = doc.data();
      final asatidzData = data['asatidz'] as Map<String, dynamic>?;
      final namaPembimbing = asatidzData?['name'] as String?;
      
      if (data['santris'] != null && namaPembimbing != null) {
        final santrisList = List<dynamic>.from(data['santris']);
         for (final item in santrisList) {
           if (item is Map && item['id'] != null) {
              classMap[item['id'].toString().trim()] = namaPembimbing;
           }
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
        tipeKelas: s.tipeKelas,
        pembimbing: classMap[s.id.trim()] ?? 'Belum ada',
      );
    }).toList();
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async {
    final detail = await remote.getSantriDetail(id);

    // Fetch pembimbing from halaqahs collection
    final halaqahSnap = await firestore
        .collection('halaqahs')
        .where('status', isEqualTo: 'Active')
        .get();

    String? namaPembimbing;
    for (var doc in halaqahSnap.docs) {
      final data = doc.data();
      final santris = data['santris'] as List<dynamic>? ?? [];
      final found = santris.any((s) => s is Map && s['id'] == id);
      if (found) {
        final asatidz = data['asatidz'] as Map<String, dynamic>?;
        namaPembimbing = asatidz?['name'];
        break;
      }
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

  @override
  Future<List<SantriEntity>> getSantriByIds(List<String> ids) async {
    final santriList = await remote.getSantriByIds(ids);

    // Fetch pembimbing info
    final halaqahSnap = await firestore
        .collection('halaqahs')
        .where('status', isEqualTo: 'Active')
        .get();

    final classMap = <String, String>{};

    for (var doc in halaqahSnap.docs) {
      final data = doc.data();
      final asatidzData = data['asatidz'] as Map<String, dynamic>?;
      final namaPembimbing = asatidzData?['name'] as String?;
      
      if (data['santris'] != null && namaPembimbing != null) {
        final santrisList = List<dynamic>.from(data['santris']);
         for (final item in santrisList) {
           if (item is Map && item['id'] != null) {
              classMap[item['id'].toString().trim()] = namaPembimbing;
           }
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
        tipeKelas: s.tipeKelas,
        pembimbing: classMap[s.id.trim()] ?? 'Belum ada',
      );
    }).toList();
  }
  @override
  Future<List<AsatidzEntity>> getAsatidzList() async {
    return await remote.getAsatidzList();
  }
}
