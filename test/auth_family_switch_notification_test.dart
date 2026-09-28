// Firebase plugin interfaces are replaced with minimal test doubles here.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/notifications/fcm_token_datasource.dart';
import 'package:khoirunnasyien/core/notifications/notification_service.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/data/model/user_model.dart';
import 'package:khoirunnasyien/features/auth/domain/auth_repository.dart';
import 'package:khoirunnasyien/features/auth/domain/user_repository.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';

void main() {
  test(
    'switch memindahkan token notifikasi setelah sesi target aktif',
    () async {
      final events = <String>[];
      final auth = _AuthRepository(events);
      final notifications = _NotificationService(events);
      final cubit = AuthCubit(
        auth,
        _UserRepository(),
        notifications,
        _FamilyRepository(events),
      );
      addTearDown(cubit.close);

      await cubit.checkAuth();
      events.clear();

      final error = await cubit.switchSantri('target');

      expect(error, isNull);
      expect(events, [
        'token:target',
        'notification:clear:old',
        'auth:target',
        'notification:register:target:santri',
      ]);
      expect(auth.uid, 'target');
      expect((cubit.state as AuthAuthenticated).user.uid, 'target');
    },
  );

  test('notifikasi akun lama dipulihkan bila sesi target gagal', () async {
    final events = <String>[];
    final auth = _AuthRepository(events)..failSwitch = true;
    final notifications = _NotificationService(events);
    final cubit = AuthCubit(
      auth,
      _UserRepository(),
      notifications,
      _FamilyRepository(events),
    );
    addTearDown(cubit.close);

    await cubit.checkAuth();
    events.clear();

    final error = await cubit.switchSantri('target');

    expect(error, isNotNull);
    expect(events, [
      'token:target',
      'notification:clear:old',
      'auth:target:failed',
      'notification:register:old:admin',
    ]);
    expect(auth.uid, 'old');
    expect((cubit.state as AuthAuthenticated).user.uid, 'old');
  });
}

class _AuthRepository implements AuthRepository {
  _AuthRepository(this.events);

  final List<String> events;
  String uid = 'old';
  bool failSwitch = false;

  @override
  User? currentUser() => _FirebaseUser(uid);

  @override
  Future<void> loginWithCustomToken(String token) async {
    if (failSwitch) {
      events.add('auth:target:failed');
      throw FirebaseAuthException(code: 'network-request-failed');
    }
    uid = token.substring('token-'.length);
    events.add('auth:$uid');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FirebaseUser implements User {
  _FirebaseUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepository implements UserRepository {
  @override
  Future<UserModel> getUserByUid(String uid) async => UserModel(
    uid: uid,
    name: uid,
    nis: uid,
    email: '$uid@example.test',
    role: uid == 'old' ? UserRole.admin : UserRole.santri,
    phone: '',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FamilyRepository extends FamilyRepository {
  _FamilyRepository(this.events)
    : super(_UnusedFirestore(), _UnusedFunctions());

  final List<String> events;

  @override
  Future<String> createSwitchToken(String targetSantriId) async {
    events.add('token:$targetSantriId');
    return 'token-$targetSantriId';
  }
}

class _NotificationService extends NotificationService {
  _NotificationService(this.events)
    : super(_UnusedMessaging(), FcmTokenDataSource(_UnusedFirestore()));

  final List<String> events;
  String activeUid = 'old';

  @override
  Future<void> clear() async {
    events.add('notification:clear:$activeUid');
    activeUid = '';
  }

  @override
  Future<void> registerForUser({
    required String uid,
    required String role,
  }) async {
    activeUid = uid;
    events.add('notification:register:$uid:$role');
  }
}

class _UnusedFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedFunctions implements FirebaseFunctions {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedMessaging implements FirebaseMessaging {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
