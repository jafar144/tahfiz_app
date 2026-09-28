// Test doubles exercise the datasource without a Firebase connection.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_schedule/data/datasource/schedule_remote_datasource.dart';

void main() {
  for (final error in <Object>[
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    PlatformException(
      code: 'firebase_firestore',
      message: 'PERMISSION_DENIED: Missing or insufficient permissions.',
      details: {'code': 'permission-denied'},
    ),
  ]) {
    test(
      'pembimbing tetap dimuat saat hitungan ditolak: ${error.runtimeType}',
      () async {
        final source = ScheduleRemoteDataSourceImpl(
          _Firestore(countError: error),
        );

        final halaqah = await source.getHalaqahBySantriId('santri');

        expect(halaqah?.teacherId, 'teacher');
        expect(halaqah?.teacherName, 'Pembimbing Terkini');
        expect(halaqah?.santriCount, 4);
      },
    );
  }

  test('error hitungan selain izin tidak disembunyikan', () async {
    final error = PlatformException(
      code: 'firebase_firestore',
      details: {'code': 'unavailable'},
    );
    final source = ScheduleRemoteDataSourceImpl(_Firestore(countError: error));
    await expectLater(
      source.getHalaqahBySantriId('santri'),
      throwsA(same(error)),
    );
  });

  test('hitungan terbaru tetap digunakan saat akun memiliki izin', () async {
    final source = ScheduleRemoteDataSourceImpl(_Firestore());
    final halaqah = await source.getHalaqahBySantriId('santri');
    expect(halaqah?.santriCount, 7);
  });
}

class _Firestore implements FirebaseFirestore {
  final Object? countError;
  _Firestore({this.countError});

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(path, countError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Collection implements CollectionReference<Map<String, dynamic>> {
  @override
  final String path;
  final Object? countError;
  _Collection(this.path, this.countError);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Document(path, id!);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) return _Query(countError);
    return super.noSuchMethod(invocation);
  }
}

class _Document implements DocumentReference<Map<String, dynamic>> {
  final String collectionPath;
  @override
  final String id;
  _Document(this.collectionPath, this.id);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return _Snapshot(id, switch (collectionPath) {
      'santri_profiles' => {'halaqah_id': 'halaqah'},
      'halaqahs' => {
        'asatidz': {'id': 'teacher'},
        'santri_count': 4,
      },
      'asatidz_profiles' => {'name': 'Pembimbing Terkini'},
      _ => throw StateError('Unexpected collection: $collectionPath'),
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> value;
  _Snapshot(this.id, this.value);

  @override
  bool get exists => true;
  @override
  Map<String, dynamic> data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Query implements Query<Map<String, dynamic>> {
  final Object? error;
  _Query(this.error);

  @override
  AggregateQuery count() => _CountQuery(error);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountQuery implements AggregateQuery {
  final Object? error;
  _CountQuery(this.error);

  @override
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async {
    if (error != null) throw error!;
    return _CountSnapshot();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountSnapshot implements AggregateQuerySnapshot {
  @override
  int get count => 7;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
