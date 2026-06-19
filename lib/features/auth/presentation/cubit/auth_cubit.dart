import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/notifications/notification_service.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/domain/auth_repository.dart';
import 'package:khoirunnasyien/features/auth/domain/user_repository.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final UserRepository userRepository;
  final NotificationService notificationService;

  AuthCubit(this.authRepository, this.userRepository, this.notificationService)
      : super(AuthInitial());

  /// Daftarkan token perangkat untuk user (role dipakai untuk penargetan
  /// notifikasi di server). Fire-and-forget agar tidak menunda navigasi.
  void _registerNotifications(UserRole role, String uid) {
    unawaited(notificationService.registerForUser(
      uid: uid,
      role: role.toRoleString(),
    ));
  }

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

    if (user.role == UserRole.santri) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('santri_profiles')
          .where('nis', isEqualTo: user.nis)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        if (data['is_active'] == false) {
          await authRepository.logout();
          emit(AuthUnauthenticated());
          return;
        }
      }
    }

    _registerNotifications(user.role, user.uid);
    emit(AuthAuthenticated(user));
  }

  Future<void> login(String nis, String password) async {
    try {
      emit(AuthLoading());
      await authRepository.login(nis, password);
      
      final firebaseUser = authRepository.currentUser();
      if (firebaseUser == null) {
        throw Exception('Proses login gagal, silakan periksa kredensial Anda.');
      }

      final user = await userRepository.getUserByUid(firebaseUser.uid);

      if (user.role == UserRole.santri) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('santri_profiles')
            .where('nis', isEqualTo: user.nis)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          if (data['is_active'] == false) {
            await authRepository.logout();
            throw Exception('Gagal masuk. Akun santri ini sudah tidak aktif.');
          }
        }
      }

      _registerNotifications(user.role, user.uid);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> logout() async {
    SantriHomeCubit.overrideSantriId = null;
    await notificationService.clear();
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> switchSantri(String santriId) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('santri_profiles')
          .doc(santriId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      SantriHomeCubit.overrideSantriId = santriId;

      final switchedUser = currentState.user.copyWith(
        name: data['name'] ?? currentState.user.name,
        nis: data['nis'] ?? currentState.user.nis,
        phone: data['phone'] ?? currentState.user.phone,
      );

      emit(AuthAuthenticated(switchedUser));
    } catch (_) {}
  }

  Future<void> switchRole() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final currentUser = currentState.user;
      if (!currentUser.isAdmin) return;

      final newRole = currentUser.role == UserRole.admin
          ? UserRole.asatidz
          : UserRole.admin;

      try {
        emit(AuthLoading());
        await userRepository.updateUserRole(currentUser.uid, newRole);
        
        final user = await userRepository.getUserByUid(currentUser.uid);
        _registerNotifications(user.role, user.uid);
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(ErrorHandler.getMessage(e)));
        // Restore previous state if needed, but for now error state is fine or could log and restore
        emit(currentState);
      }
    }
  }
}
