import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';

class AsatidzRemoteDataSourceImpl implements AsatidzRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  AsatidzRemoteDataSourceImpl(this.firestore, this.auth);

  @override
  Future<List<AsatidzEntity>> getAsatidzList({
    String? keyword,
    bool? isActive,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    Query query = firestore.collection('asatidz_profiles');

    if (isActive != null) {
      query = query.where('is_active', isEqualTo: isActive);
    }

    bool isSearching = keyword != null && keyword.isNotEmpty;
    
    if (!isSearching) {
      query = query.limit(limit);
      if (lastDocumentId != null) {
        final lastDoc = await firestore.collection('asatidz_profiles').doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
    }

    final snapshot = await query.get();

    var docs = snapshot.docs;

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

      return AsatidzEntity(
        id: doc.id,
        name: data['name'] ?? '',
        nis: data['nis'] ?? '',
        jenisKelamin: data['jenis_kelamin'] ?? '',
        isActive: data['is_active'] ?? true,
      );
    }).toList();
  }

  @override
  Future<AsatidzDetail> getAsatidzDetail(String id) async {
    final doc = await firestore.collection('asatidz_profiles').doc(id).get();
    final userDoc = await firestore.collection('users').doc(id).get();

    if (!doc.exists) {
      throw Exception('Asatidz not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    final userData = userDoc.exists
        ? userDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};

    return AsatidzDetail(
      id: doc.id,
      name: data['name'] ?? '',
      nis: data['nis'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? '',
      isActive: data['is_active'] ?? true,
      phone: userData['phone'] ?? '',
    );
  }

  @override
  Future<void> addAsatidz(AsatidzParams params) async {
    final email = '${params.nis}@khoirunnasyien.app';
    final password = 'Khoirun123';

    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'tempAuthAsatidz', // Different name to avoid conflict
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
        'role': 'asatidz',
        'uid': uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      await firestore.collection('asatidz_profiles').doc(uid).set({
        'is_active': true,
        'jenis_kelamin': params.jenisKelamin,
        'name': params.name,
        'nis': params.nis,
        'uid': uid,
        'created_at': FieldValue.serverTimestamp(),
      });
    } finally {
      await tempApp?.delete();
    }
  }

  @override
  Future<void> updateAsatidz(String id, AsatidzParams params) async {
    await firestore.collection('asatidz_profiles').doc(id).update({
      'name': params.name,
      'nis': params.nis,
      'jenis_kelamin': params.jenisKelamin,
      'is_active': params.isActive,
    });

    await firestore.collection('users').doc(id).update({
      'name': params.name,
      'phone': params.phone,
      'nis': params.nis,
    });
  }
}
