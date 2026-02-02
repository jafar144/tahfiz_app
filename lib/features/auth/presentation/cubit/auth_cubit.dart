
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/auth/domain/auth_repository.dart';
import 'package:khoirunnasyien/features/auth/domain/user_repository.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  AuthCubit(this.authRepository, this.userRepository) : super(AuthInitial());

  Future<String> getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> checkAuth() async {
    final firebaseUser = authRepository.currentUser();

    if (firebaseUser == null) {
      emit(AuthUnauthenticated());
      return;
    }

    final user = await userRepository.getUserByUid(firebaseUser.uid);
    emit(AuthAuthenticated(user));
  }

  Future<void> login(String nis, String password) async {
    try {
      emit(AuthLoading());
      await authRepository.login(nis, password);
      
      final firebaseUser = authRepository.currentUser();
      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      final user = await userRepository.getUserByUid(firebaseUser.uid);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
