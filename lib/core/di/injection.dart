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
import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource.dart' as mgmt_asatidz_ds;
import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource_impl.dart' as mgmt_asatidz_ds_impl;
import 'package:khoirunnasyien/features/management_asatidz/data/repository/asatidz_repository_impl.dart' as mgmt_asatidz_repo;
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart' as mgmt_asatidz_domain;
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_cubit.dart';

import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource_impl.dart';
import 'package:khoirunnasyien/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/input_payment_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/data/datasource/schedule_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_schedule/data/repositories/schedule_repository_impl.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/data/datasources/asatidz_remote_datasource.dart';
import 'package:khoirunnasyien/features/asatidz/data/repositories/asatidz_repository_impl.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart' as asatidz_domain;
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_santri_cubit.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_cubit.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_setoran_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/data/datasources/monthly_report_remote_datasource.dart';
import 'package:khoirunnasyien/features/monthly_report/data/repositories/monthly_report_repository_impl.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_cubit.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_cubit.dart';


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

  getIt.registerLazySingleton<mgmt_asatidz_ds.AsatidzRemoteDataSource>(
    () => mgmt_asatidz_ds_impl.AsatidzRemoteDataSourceImpl(getIt(), getIt()),
  );

  getIt.registerLazySingleton<ScheduleRemoteDataSource>(
    () => ScheduleRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<AsatidzRemoteDataSource>(
    () => AsatidzRemoteDataSourceImpl(firestore: getIt()),
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

  getIt.registerLazySingleton<mgmt_asatidz_domain.AsatidzRepository>(
    () => mgmt_asatidz_repo.AsatidzRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(getIt()),
  );  

  getIt.registerLazySingleton<asatidz_domain.AsatidzRepository>(
    () => AsatidzRepositoryImpl(remoteDataSource: getIt()),
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

  getIt.registerFactory(
    () => AsatidzCubit(getIt()),
  );

  getIt.registerFactory(
    () => AsatidzDetailCubit(getIt()),
  );

  // Payment
  getIt.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerFactory(
    () => PaymentCubit(getIt(), getIt()),
  );

  getIt.registerFactory(
    () => InputPaymentCubit(getIt()),
  );

  getIt.registerFactory(
    () => SantriPaymentHistoryCubit(getIt()),
  );

  getIt.registerFactory(
    () => FinancialReportCubit(getIt(), getIt()),
  );

  getIt.registerFactory(
    () => ScheduleCubit(getIt()),
  );

  getIt.registerFactory(
    () => AddHalaqahCubit(
      scheduleRepository: getIt(),
      asatidzRepository: getIt(),
      santriRepository: getIt(),
    ),
  );

  getIt.registerFactoryParam<HalaqahDetailCubit, Halaqah, void>(
    (halaqah, _) => HalaqahDetailCubit(
      scheduleRepository: getIt(),
      asatidzRepository: getIt(),
      santriRepository: getIt(),
      halaqah: halaqah,
    ),
  );

  getIt.registerFactory(
    () => AsatidzDashboardCubit(
      scheduleRepository: getIt(),
      asatidzRepository: getIt(),
      asatidzId: '', // Will be set from auth
    ),
  );

  getIt.registerFactory(
    () => AsatidzSantriCubit(
      scheduleRepository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => SantriHomeCubit(
      santriRepository: getIt(),
      paymentRepository: getIt(),
      scheduleRepository: getIt(),
      asatidzRepository: getIt(),
      mgmtAsatidzRepository: getIt(),
      monthlyReportRepository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => SantriSetoranCubit(getIt()),
  );

  // Monthly Report
  getIt.registerLazySingleton<MonthlyReportRemoteDataSource>(
    () => MonthlyReportRemoteDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<MonthlyReportRepository>(
    () => MonthlyReportRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerFactory(
    () => MonthlyReportCubit(
      reportRepository: getIt(),
      scheduleRepository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => MonthlyReportInputCubit(repository: getIt()),
  );

  getIt.registerFactory(
    () => SantriMonthlyReportCubit(repository: getIt()),
  );

  getIt.registerFactory(
    () => AdminAssessmentCubit(
      scheduleRepository: getIt(),
      reportRepository: getIt(),
      asatidzRepository: getIt(),
    ),
  );

  // Family
  getIt.registerLazySingleton(
    () => FamilyRepository(getIt()),
  );

  getIt.registerFactory(
    () => FamilyCubit(
      familyRepository: getIt(),
      santriRepository: getIt(),
    ),
  );
}