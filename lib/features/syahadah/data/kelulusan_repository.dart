import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

const kelulusanNetworkErrorMessage =
    'Tidak ada koneksi internet. Periksa jaringan Anda, lalu coba lagi.';
const kelulusanFeatureUnavailableMessage =
    'Fitur foto kelulusan belum tersedia di server. Silakan hubungi admin.';

const _kelulusanNetworkErrorCodes = {
  'cancelled',
  'deadline-exceeded',
  'network-request-failed',
  'unavailable',
};

class KelulusanNetworkException implements Exception {
  final String message;

  const KelulusanNetworkException([
    this.message = kelulusanNetworkErrorMessage,
  ]);

  @override
  String toString() => message;
}

class KelulusanAlreadyExistsException implements Exception {
  final String message;
  final int? existingCount;

  const KelulusanAlreadyExistsException(this.message, {this.existingCount});

  @override
  String toString() => message;
}

class KelulusanRemoteException implements Exception {
  final String message;
  final String? code;

  const KelulusanRemoteException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Memetakan payload error callable tanpa bergantung pada instance Firebase.
///
/// Endpoint callable yang belum ter-deploy mengembalikan `not-found` dengan
/// pesan mentah `NOT_FOUND`. Pesan bisnis dari handler tetap dipertahankan.
Exception mapKelulusanFunctionsError({
  required String code,
  String? message,
  Object? details,
}) {
  if (_kelulusanNetworkErrorCodes.contains(code)) {
    return const KelulusanNetworkException();
  }
  if (code == 'already-exists') {
    final existingCount = details is Map
        ? (details['existingCount'] as num?)?.toInt()
        : null;
    return KelulusanAlreadyExistsException(
      message ?? 'Foto kelulusan santri ini sudah ada untuk hari ini.',
      existingCount: existingCount,
    );
  }

  final normalizedMessage = message?.trim().toUpperCase().replaceAll(
    RegExp(r'[\s_-]'),
    '',
  );
  if (code == 'not-found' && normalizedMessage == 'NOTFOUND') {
    return const KelulusanRemoteException(
      kelulusanFeatureUnavailableMessage,
      code: 'not-found',
    );
  }

  return KelulusanRemoteException(
    message ?? 'Foto kelulusan belum berhasil disimpan.',
    code: code,
  );
}

class KelulusanDailyStatus {
  final String dateKey;
  final int existingCount;
  final String revision;

  const KelulusanDailyStatus({
    required this.dateKey,
    required this.existingCount,
    required this.revision,
  });

  bool get exists => existingCount > 0;
}

String kelulusanUploadFileName({
  required String santriId,
  required String dateKey,
  required String operationId,
}) {
  return '${santriId}_${dateKey}_$operationId';
}

/// Satu entri kelulusan/wisuda santri yang tampil di carousel Home santri.
class KelulusanEntity {
  final String id;
  final String santriId;
  final String santriName;
  final String kelas;
  final String hafalan;
  final String imageUrl;
  final String operationId;
  final DateTime createdAt;

  KelulusanEntity({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.kelas,
    required this.hafalan,
    required this.imageUrl,
    required this.operationId,
    required this.createdAt,
  });

  factory KelulusanEntity.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return KelulusanEntity(
      id: doc.id,
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      kelas: data['kelas'] ?? '',
      hafalan: data['hafalan'] ?? '',
      imageUrl: data['image_url'] ?? '',
      operationId: data['operation_id'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class KelulusanRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  KelulusanRepository(this._firestore, this._functions);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('kelulusan');

  Future<KelulusanDailyStatus> checkToday({required String santriId}) async {
    try {
      final result = await _functions
          .httpsCallable('checkKelulusanPhoto')
          .call<Map<String, dynamic>>({'santriId': santriId})
          .timeout(const Duration(seconds: 12));
      final data = result.data;
      final dateKey = data['dateKey'] as String? ?? '';
      final revision = data['revision'] as String? ?? '';
      if (dateKey.isEmpty || revision.isEmpty) {
        throw const KelulusanRemoteException(
          'Data foto kelulusan tidak dapat diperiksa.',
        );
      }
      return KelulusanDailyStatus(
        dateKey: dateKey,
        existingCount: (data['existingCount'] as num?)?.toInt() ?? 0,
        revision: revision,
      );
    } catch (error) {
      throw _mapCallableError(error);
    }
  }

  Future<void> reserveUpload({
    required String santriId,
    required String dateKey,
    required String operationId,
    required String expectedRevision,
    required bool replaceExisting,
  }) async {
    try {
      await _functions
          .httpsCallable('reserveKelulusanPhoto')
          .call<Map<String, dynamic>>({
            'santriId': santriId,
            'dateKey': dateKey,
            'operationId': operationId,
            'expectedRevision': expectedRevision,
            'replaceExisting': replaceExisting,
          })
          .timeout(const Duration(seconds: 12));
    } catch (error) {
      throw _mapCallableError(error);
    }
  }

  Future<void> saveKelulusan({
    required String santriId,
    required String santriName,
    required String kelas,
    required String hafalan,
    required String imageUrl,
    required String dateKey,
    required String operationId,
    required bool replaceExisting,
  }) async {
    try {
      await _functions
          .httpsCallable('saveKelulusanPhoto')
          .call<Map<String, dynamic>>({
            'santriId': santriId,
            'santriName': santriName,
            'kelas': kelas,
            'hafalan': hafalan,
            'imageUrl': imageUrl,
            'dateKey': dateKey,
            'operationId': operationId,
            'replaceExisting': replaceExisting,
          })
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      throw _mapCallableError(error);
    }
  }

  Exception _mapCallableError(Object error) {
    if (error is KelulusanNetworkException) return error;
    if (error is KelulusanAlreadyExistsException) return error;
    if (error is KelulusanRemoteException) return error;
    if (error is TimeoutException || error is SocketException) {
      return const KelulusanNetworkException();
    }
    if (error is FirebaseFunctionsException) {
      return mapKelulusanFunctionsError(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    }
    return const KelulusanRemoteException(
      'Foto kelulusan belum berhasil disimpan. Silakan coba lagi.',
    );
  }

  Query<Map<String, dynamic>> _query({
    required int limit,
    required bool activeOnly,
  }) {
    Query<Map<String, dynamic>> query = _collection;
    if (activeOnly) {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      query = query.where(
        'created_at',
        isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
      );
    }
    return query.orderBy('created_at', descending: true).limit(limit);
  }

  /// [activeOnly] mengikuti batas tampil Home Santri, yaitu tujuh hari.
  Future<List<KelulusanEntity>> getKelulusan({
    int limit = 20,
    bool activeOnly = true,
  }) async {
    final snap = await _query(limit: limit, activeOnly: activeOnly).get();
    return snap.docs.map((d) => KelulusanEntity.fromDoc(d)).toList();
  }

  Stream<List<KelulusanEntity>> watchKelulusan({
    int limit = 20,
    bool activeOnly = true,
  }) {
    return _query(limit: limit, activeOnly: activeOnly).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => KelulusanEntity.fromDoc(doc)).toList(),
    );
  }

  Future<void> deleteKelulusan(KelulusanEntity item) async {
    try {
      await _functions.httpsCallable('deleteKelulusanPhoto').call({
        'id': item.id,
        'expectedImageUrl': item.imageUrl,
        'expectedOperationId': item.operationId,
      });
    } catch (error) {
      throw _mapCallableError(error);
    }
  }
}
