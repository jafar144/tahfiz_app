import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDatasource {
  Future<void> login(String nis, String password);
  Future<void> loginWithCustomToken(String token);
  User? currentUser();
  bool isLoggedIn();
  Future<void> logout();
}
