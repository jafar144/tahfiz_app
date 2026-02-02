import 'package:khoirunnasyien/features/auth/domain/user_repository.dart';

import '../datasource/user_remote_datasource.dart';
import '../model/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource remoteDatasource;

  UserRepositoryImpl(this.remoteDatasource);

  @override
  Future<UserModel> getUserByUid(String uid) {
    return remoteDatasource.getUserByUid(uid);
  }
}