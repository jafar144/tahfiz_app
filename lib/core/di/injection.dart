import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:khoirunnasyien/core/firebase/auth_client.dart';
import 'package:khoirunnasyien/core/firebase/firestore_client.dart';
import 'package:khoirunnasyien/core/firebase/storage_client.dart';
import 'package:khoirunnasyien/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:khoirunnasyien/features/auth/data/datasource/auth_remote_datasource_impl.dart';
import 'package:khoirunnasyien/features/auth/data/datasource/user_remote_datasource.dart';
import 'package:khoirunnasyien/features/auth/data/datasource/user_remote_datasource_impl.dart';
import 'package:khoirunnasyien/features/auth/data/repository/auth_repository_impl.dart';
import 'package:khoirunnasyien/features/auth/data/repository/user_repository_impl.dart';
import 'package:khoirunnasyien/features/auth/domain/auth_repository.dart';
import 'package:khoirunnasyien/features/auth/domain/user_repository.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // Firebase
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseStorage.instance);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);

  // Clients
  getIt.registerLazySingleton(() => FirestoreClient(getIt()));
  getIt.registerLazySingleton(() => StorageClient(getIt()));
  getIt.registerLazySingleton(() => AuthClient(getIt()));

  // Datasource
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(getIt()),
  );

  getIt.registerLazySingleton<UserRemoteDatasource>(
    () => UserRemoteDatasourceImpl(getIt()),
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt()),
  );

  // Cubit
  getIt.registerFactory(
    () => AuthCubit(getIt(), getIt()),
  );
}