import 'package:cloud_firestore/cloud_firestore.dart';

/// Mengelola dokumen token perangkat di Firestore (koleksi `device_tokens`).
///
/// Doc id = token FCM (idempotent), berisi `uid` & `role` pemilik agar Cloud
/// Functions bisa menargetkan notifikasi per-user maupun per-role.
class FcmTokenDataSource {
  final FirebaseFirestore _firestore;

  FcmTokenDataSource(this._firestore);

  static const _collection = 'device_tokens';

  Future<void> saveToken({
    required String token,
    required String uid,
    required String role,
  }) async {
    await _firestore.collection(_collection).doc(token).set({
      'token': token,
      'uid': uid,
      'role': role,
      'platform': 'android',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteToken(String token) async {
    await _firestore.collection(_collection).doc(token).delete();
  }
}
