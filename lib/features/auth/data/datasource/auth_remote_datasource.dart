import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDatasource {
  Future<void> login(String nis, String password);  
  User? currentUser();
  bool isLoggedIn();
  Future<void> logout();
}