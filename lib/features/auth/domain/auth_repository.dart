import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<void> login(String nis, String password);
  Future<void> loginWithCustomToken(String token);
  bool isLoggedIn();
  User? currentUser();
  Future<void> logout();
}
