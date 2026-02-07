import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';

class SantriRemoteDataSourceImpl implements SantriRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SantriRemoteDataSourceImpl(this.firestore, this.auth);

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
  }) async {
    Query query = firestore.collection('santri_profiles');

    if (isActive != null) {
      query = query.where('is_active', isEqualTo: isActive);
    }

    final snapshot = await query.get();

    var docs = snapshot.docs;

    // Filter by keyword (Search logic) - client side for flexibility
    if (keyword != null && keyword.isNotEmpty) {
      final k = keyword.toLowerCase();
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final nis = (data['nis'] ?? '').toString().toLowerCase();
        return name.contains(k) || nis.contains(k);
      }).toList();
    }

    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return SantriEntity(
        id: doc.id,
        name: data['name'],
        nis: data['nis'],
        kelas: data['kelas'],
        jenisKelamin: data['jenis_kelamin'],
        isActive: data['is_active'] ?? true,
        isFree: data['is_free'] ?? false,
        nomorWali: data['nomor_wali'],
        pembimbing: null,
      );
    }).toList();
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

    return SantriDetail(
      id: doc.id,
      name: data['name'] ?? '',
      nis: data['nis'] ?? '',
      kelas: data['kelas'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? '',
      isActive: data['is_active'] ?? true,
      isFree: data['is_free'] ?? false,
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
        'is_free': params.isFree,
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
      'is_free': params.isFree,
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
}
