import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:khoirunnasyien/core/utils/role.dart';
import '../model/user_model.dart';
import 'user_remote_datasource.dart';

class UserRemoteDatasourceImpl implements UserRemoteDatasource {
  final FirebaseFirestore firestore;

  UserRemoteDatasourceImpl(this.firestore);

  @override
  Future<UserModel> getUserByUid(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Pengguna tidak ditemukan');
    }

    debugPrint(doc.data()!.toString());
    return UserModel.fromJson(uid, doc.data()!);
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    await firestore.collection('users').doc(uid).update({
      'role': role.toRoleString(),
    });
  }
}
