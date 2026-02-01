import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:tahfiz_app/core/firebase/firestore_client.dart';
import 'package:tahfiz_app/core/firebase/storage_client.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // Firebase
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseStorage.instance);

  // Clients
  getIt.registerLazySingleton(() => FirestoreClient(getIt()));
  getIt.registerLazySingleton(() => StorageClient(getIt()));
}