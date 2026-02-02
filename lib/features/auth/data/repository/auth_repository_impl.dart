import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:khoirunnasyien/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  @override
  User? currentUser() => remoteDatasource.currentUser();

  @override
  Future<void> login(String nis, String password) {
    return remoteDatasource.login(nis, password);
  }

  @override
  bool isLoggedIn() {
    return remoteDatasource.isLoggedIn();
  }

  @override
  Future<void> logout() {
    return remoteDatasource.logout();
  }
}
