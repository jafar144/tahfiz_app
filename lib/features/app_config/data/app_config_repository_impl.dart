import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/runtime_app_config.dart';
import 'package:khoirunnasyien/features/app_config/domain/repositories/app_config_repository.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  static const collectionName = 'app_config';
  static const documentName = 'runtime';

  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  AppConfigRepositoryImpl({required this.firestore, required this.functions});

  DocumentReference<Map<String, dynamic>> get _document {
    return firestore.collection(collectionName).doc(documentName);
  }

  @override
  Stream<RuntimeAppConfig> watch() {
    return _document.snapshots().map((snapshot) {
      return RuntimeAppConfig.fromMap(snapshot.data());
    });
  }

  @override
  Future<void> setFeatureEnabled(AppFeature feature, bool enabled) async {
    await functions.httpsCallable('setAppFeatureConfig').call({
      'feature': feature.key,
      'enabled': enabled,
    });
  }
}
