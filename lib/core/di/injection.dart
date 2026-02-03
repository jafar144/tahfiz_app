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
import 'package:khoirunnasyien/features/home/data/datasource/admin_home_remote_datasource.dart';
import 'package:khoirunnasyien/features/home/data/datasource/admin_home_remote_datasource_impl.dart';
import 'package:khoirunnasyien/features/home/data/repository/admin_home_repository_impl.dart';
import 'package:khoirunnasyien/features/home/domain/repositories/admin_home_repository.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource_impl.dart';
import 'package:khoirunnasyien/features/management_santri/data/repository/santri_repository_impl.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';


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

  getIt.registerLazySingleton<AdminHomeRemoteDatasource>(
    () => AdminHomeRemoteDatasourceImpl(getIt()),
  );

  getIt.registerLazySingleton<SantriRemoteDataSource>(
    () => SantriRemoteDataSourceImpl(getIt(), getIt()),
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<AdminHomeRepository>(
    () => AdminHomeRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerLazySingleton<SantriRepository>(
    () => SantriRepositoryImpl(getIt(), getIt()),
  );  

  // Cubit
  getIt.registerFactory(
    () => AuthCubit(getIt(), getIt()),
  );

  getIt.registerFactory(
    () => AdminHomeCubit(getIt(), getIt()),
  );

  getIt.registerFactory(
    () => SantriCubit(getIt()),
  );

  getIt.registerFactory(
    () => SantriDetailCubit(getIt()),
  );
}