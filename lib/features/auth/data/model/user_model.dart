import 'package:khoirunnasyien/core/utils/role.dart';

class UserModel {
  final String uid;
  final String name;
  final String nis;
  final String email;
  final UserRole role;
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.nis,
    required this.email,
    required this.role,
    required this.phone,
  });

  factory UserModel.fromJson(String uid, Map<String, dynamic> json) {
    return UserModel(
      uid: uid,
      name: json['name'],
      nis: json['nis'],
      email: json['email'],
      role: (json['role'] as String).toRole(),
      phone: json['phone'],
    );
  }
}
