import '../model/user_model.dart';

abstract class UserRemoteDatasource {
  Future<UserModel> getUserByUid(String uid);
}
