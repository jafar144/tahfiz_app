import 'package:khoirunnasyien/core/utils/role.dart';
import '../model/user_model.dart';

abstract class UserRemoteDatasource {
  Future<UserModel> getUserByUid(String uid);
  Future<void> updateUserRole(String uid, UserRole role);
}
