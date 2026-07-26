import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/features/auth/data/datasource/auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDatasourceImpl(this.firebaseAuth);

  @override
  Future<void> login(String nis, String password) async {
    final email = '$nis@${AppConfig.current.authEmailDomain}';

    await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  User? currentUser() => firebaseAuth.currentUser;

  @override
  bool isLoggedIn() {
    return firebaseAuth.currentUser != null;
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
