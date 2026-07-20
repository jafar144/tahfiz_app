import 'package:khoirunnasyien/core/utils/role.dart';

class UserModel {
  final String uid;
  final String name;
  final String nis;
  final String email;
  final UserRole role;
  final String phone;
  final bool isAdmin;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.nis,
    required this.email,
    required this.role,
    required this.phone,
    this.isAdmin = false,
    this.photoUrl,
  });

  factory UserModel.fromJson(String uid, Map<String, dynamic> json) {
    return UserModel(
      uid: uid,
      name: json['name'] ?? '',
      nis: json['nis'] ?? '',
      email: json['email'] ?? '',
      role: (json['role'] as String).toRole(),
      phone: json['phone'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      photoUrl: json['photo_url'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? nis,
    String? email,
    UserRole? role,
    String? phone,
    bool? isAdmin,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nis: nis ?? this.nis,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isAdmin: isAdmin ?? this.isAdmin,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
