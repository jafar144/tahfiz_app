import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/data/model/user_model.dart';

abstract class UserRepository {
  Future<UserModel> getUserByUid(String uid);
  Future<void> updateUserRole(String uid, UserRole role);
}
