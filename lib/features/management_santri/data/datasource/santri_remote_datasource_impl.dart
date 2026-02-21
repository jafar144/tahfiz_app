import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

class SantriRemoteDataSourceImpl implements SantriRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SantriRemoteDataSourceImpl(this.firestore, this.auth);

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
    if (asatidzId != null) {
      // 1. Get halaqahs for this asatidz
      final halaqahs = await firestore
          .collection('halaqahs')
          .where('asatidz.id', isEqualTo: asatidzId)
          .get();

      final santriIds = <String>{};
      for (var doc in halaqahs.docs) {
        final data = doc.data();
        if (data['santris'] != null) {
          final list = data['santris'] as List;
          for (var item in list) {
             if (item is Map && item['id'] != null) {
              santriIds.add(item['id'].toString());
            }
          }
        }
      }

      if (santriIds.isEmpty) return [];

      // 2. Fetch santris by IDs with other filters applied
      final List<SantriEntity> allSantris = [];
      final idsList = santriIds.toList();

      // Chunking because whereIn supports max 10
      for (var i = 0; i < idsList.length; i += 10) {
        final end = (i + 10 < idsList.length) ? i + 10 : idsList.length;
        final chunk = idsList.sublist(i, end);

        Query query = firestore.collection('santri_profiles').where(FieldPath.documentId, whereIn: chunk);

        if (isActive != null) {
          query = query.where('is_active', isEqualTo: isActive);
        }
        if (gender != null) {
          query = query.where('jenis_kelamin', isEqualTo: gender);
        }
        if (session != null) {
          query = query.where('tipe_kelas', isEqualTo: session);
        }
        if (kelas != null) {
          query = query.where('kelas', isEqualTo: kelas);
        }
        // isFree tidak bisa difilter server-side di sini karena
        // Firestore melarang whereIn + isGreaterThan dalam satu query

        final snapshot = await query.get();
        final items = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
            final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
            final isFree = freeUntil != null && freeUntil.isAfter(DateTime.now());

            return SantriEntity(
            id: doc.id,
            name: data['name'],
            nis: data['nis'],
            kelas: data['kelas'],
            jenisKelamin: data['jenis_kelamin'],
            isActive: data['is_active'] ?? true,
            isFree: isFree,
            freeUntil: freeUntil,
            nomorWali: data['nomor_wali'],
            pembimbing: null,
            tipeKelas: data['tipe_kelas'],
            tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
          );
        }).toList();

        allSantris.addAll(items);
      }

      // Filter status client-side karena Firestore melarang whereIn + inequality filter
      List<SantriEntity> result = allSantris;
      if (isFree != null) {
        final now = DateTime.now();
        if (isFree == true) {
          result = result.where((s) => s.freeUntil != null && s.freeUntil!.isAfter(now)).toList();
        } else {
          result = result.where((s) => s.freeUntil == null || s.freeUntil!.isBefore(now)).toList();
        }
      }

      // 3. Filter by keyword in memory
      if (keyword != null && keyword.isNotEmpty) {
        final k = keyword.toLowerCase();
        return result.where((s) {
          final name = s.name.toLowerCase();
          final nis = s.nis.toLowerCase();
          return name.contains(k) || nis.contains(k);
        }).toList();
      }

      return result;
    }

    // Standard query building
    Query query = firestore.collection('santri_profiles');

    if (isActive != null) {
      query = query.where('is_active', isEqualTo: isActive);
    }

    if (gender != null) {
      query = query.where('jenis_kelamin', isEqualTo: gender);
    }

    if (session != null) {
      query = query.where('tipe_kelas', isEqualTo: session);
    }

    if (kelas != null) {
      query = query.where('kelas', isEqualTo: kelas);
    }

    if (isFree == true) {
      query = query.where('free_until', isGreaterThan: Timestamp.now());
    }

    // Server-side search if keyword present
    if (keyword != null && keyword.isNotEmpty) {
      // Logic:
      // If keyword contains only digits, assume it's a NIS search.
      // Otherwise, assume it's a Name search.
      final isNumeric = RegExp(r'^[0-9]+$').hasMatch(keyword);

      if (isNumeric) {
        // Query by NIS
        query = query
            .where('nis', isGreaterThanOrEqualTo: keyword)
            .where('nis', isLessThan: '$keyword\uf8ff')
            .orderBy('nis');
      } else {
        // Query by Name
        // NOTE: This is case-sensitive and prefix-only.
        
        // Attempt to capitalize first letter for better matching if names are Title Case
        String searchTerm = keyword;
        if (keyword.length > 1) {
           searchTerm = keyword[0].toUpperCase() + keyword.substring(1);
        } else {
           searchTerm = keyword.toUpperCase();
        }
        
        query = query
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThan: '$searchTerm\uf8ff')
          .orderBy('name');
      }
    } else {
      // Default ordering if no search
      query = query.orderBy('name');
    }

    query = query.limit(limit);

    if (lastDocumentId != null) {
      final lastDoc = await firestore.collection('santri_profiles').doc(lastDocumentId).get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    final now = DateTime.now();

    var result = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
      final isFreeVal = freeUntil != null && freeUntil.isAfter(now);

      return SantriEntity(
        id: doc.id,
        name: data['name'],
        nis: data['nis'],
        kelas: data['kelas'],
        jenisKelamin: data['jenis_kelamin'],
        isActive: data['is_active'] ?? true,
        isFree: isFreeVal,
        freeUntil: freeUntil,
        nomorWali: data['nomor_wali'],
        pembimbing: null,
        tipeKelas: data['tipe_kelas'],
        tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      );
    }).toList();

    // Filter Reguler client-side karena Firestore tidak support OR query (null OR < now)
    if (isFree == false) {
      result = result.where((s) => s.freeUntil == null || s.freeUntil!.isBefore(now)).toList();
    }

    return result;
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async {
    final doc = await firestore.collection('santri_profiles').doc(id).get();
    final userDoc = await firestore.collection('users').doc(id).get();

    if (!doc.exists) {
      throw Exception('Santri not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : <String, dynamic>{};

    final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
    final isFree = freeUntil != null && freeUntil.isAfter(DateTime.now());

    return SantriDetail(
      id: doc.id,
      name: data['name'] ?? '',
      nis: data['nis'] ?? '',
      kelas: data['kelas'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? '',
      isActive: data['is_active'] ?? true,
      isFree: isFree,
      freeUntil: freeUntil,
      namaWali: data['nama_wali'],
      nomorWali: data['nomor_wali'],
      tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      tanggalLahir: (data['tanggal_lahir'] as Timestamp?)?.toDate(),
      tempatLahir: data['tempat_lahir'],
      tipeKelas: data['tipe_kelas'],
      phone: userData['phone'],
    );
  }

  @override
  Future<void> addSantri(SantriParams params) async {
    final email = '${params.nis}@khoirunnasyien.app';
    // Password format: YYYYMMDD
    final birthDate = params.birthDate;
    final password = '${birthDate.year}${birthDate.month.toString().padLeft(2, '0')}${birthDate.day.toString().padLeft(2, '0')}';

    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'tempAuth',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await firestore.collection('users').doc(uid).set({
        'name': params.name,
        'email': email,
        'nis': params.nis,
        'phone': params.phone,
        'role': 'santri',
        'uid': uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      await firestore.collection('santri_profiles').doc(uid).set({
        'is_active': true,
        'free_until': params.isFree ? Timestamp.fromDate(params.freeUntil ?? DateTime(
          DateTime.now().year + 7,
          DateTime.now().month,
          DateTime.now().day,
        )) : null,
        'jenis_kelamin': params.jenisKelamin,
        'kelas': params.kelas,
        'nama_wali': params.waliName,
        'nomor_wali': params.waliPhone,
        'name': params.name,
        'nis': params.nis,
        'tanggal_masuk': Timestamp.fromDate(params.entryDate),
        'tanggal_lahir': Timestamp.fromDate(params.birthDate),
        'tempat_lahir': params.birthPlace,
        'tipe_kelas': params.tipeKelas,
        'uid': uid,
        'created_at': FieldValue.serverTimestamp(),
      });
    } finally {
      await tempApp?.delete();
    }
  }

  @override
  Future<void> updateSantri(String id, SantriParams params) async {
    // Update Santri Profile
    await firestore.collection('santri_profiles').doc(id).update({
      'name': params.name,
      'nis': params.nis,
      'kelas': params.kelas,
      'jenis_kelamin': params.jenisKelamin,
      'free_until': params.isFree ? Timestamp.fromDate(params.freeUntil ?? DateTime(
          DateTime.now().year + 7,
          DateTime.now().month,
          DateTime.now().day,
        )) : null,
      'is_free': FieldValue.delete(), // Ensure old field is removed if present
      'nama_wali': params.waliName,
      'nomor_wali': params.waliPhone,
      'tanggal_masuk': Timestamp.fromDate(params.entryDate),
      'tanggal_lahir': Timestamp.fromDate(params.birthDate),
      'tempat_lahir': params.birthPlace,
      'tipe_kelas': params.tipeKelas,
    });

    // Update User Document
    await firestore.collection('users').doc(id).update({
      'name': params.name,
      'phone': params.phone,
      'nis': params.nis,
    });
  }

  @override
  Future<List<SantriEntity>> getSantriByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final List<SantriEntity> allSantris = [];
    
    // Firestore whereIn supports max 10 items
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      final snapshot = await firestore
          .collection('santri_profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
        final isFree = freeUntil != null && freeUntil.isAfter(DateTime.now());

        return SantriEntity(
          id: doc.id,
          name: data['name'] ?? '',
          nis: data['nis'] ?? '',
          kelas: data['kelas'] ?? '',
          jenisKelamin: data['jenis_kelamin'] ?? '',
          isActive: data['is_active'] ?? true,
          isFree: isFree,
          freeUntil: freeUntil,
          nomorWali: data['nomor_wali'],
          pembimbing: null,
          tipeKelas: data['tipe_kelas'],
          tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
        );
      }).toList();
      
      allSantris.addAll(items);
    }
    
    return allSantris;
  }
  @override
  Future<List<AsatidzEntity>> getAsatidzList() async {
    final snapshot = await firestore.collection('asatidz_profiles').where('is_active', isEqualTo: true).get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AsatidzEntity(
        id: doc.id,
        name: data['name'] ?? '',
        nis: data['nis'] ?? '',
        jenisKelamin: data['jenis_kelamin'] ?? '',
        isActive: data['is_active'] ?? true,
      );
    }).toList();
  }
}
