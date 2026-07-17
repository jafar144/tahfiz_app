import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/firebase/auth_client.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_lobby_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_cubit.dart';
import 'package:khoirunnasyien/core/firebase/firestore_client.dart';
import 'package:khoirunnasyien/core/firebase/storage_client.dart';
import 'package:khoirunnasyien/core/notifications/fcm_token_datasource.dart';
import 'package:khoirunnasyien/core/notifications/notification_service.dart';
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
import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource.dart'
    as mgmt_asatidz_ds;
import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource_impl.dart'
    as mgmt_asatidz_ds_impl;
import 'package:khoirunnasyien/features/management_asatidz/data/repository/asatidz_repository_impl.dart'
    as mgmt_asatidz_repo;
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart'
    as mgmt_asatidz_domain;
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_cubit.dart';

import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource_impl.dart';
import 'package:khoirunnasyien/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/input_payment_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/family_payment_cubit.dart';
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
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart'
    as asatidz_domain;
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
import 'package:khoirunnasyien/features/syahadah/data/kelulusan_repository.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_cubit.dart';
import 'package:khoirunnasyien/features/recitation_check/data/quran_local_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/data/transcription_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/data/recitation_repository_impl.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_energy_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_repository_impl.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_settings_store.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/data/surah_journey_repository_impl.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/repositories/surah_journey_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // Firebase
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseStorage.instance);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => FirebaseMessaging.instance);

  // Clients
  getIt.registerLazySingleton(() => FirestoreClient(getIt()));
  getIt.registerLazySingleton(() => StorageClient(getIt()));
  getIt.registerLazySingleton(() => AuthClient(getIt()));

  // Notifications
  getIt.registerLazySingleton(() => FcmTokenDataSource(getIt()));
  getIt.registerLazySingleton(() => NotificationService(getIt(), getIt()));

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
  getIt.registerFactory(() => AuthCubit(getIt(), getIt(), getIt()));

  getIt.registerFactory(() => AdminHomeCubit(getIt(), getIt()));

  getIt.registerFactory(() => SantriCubit(getIt()));

  getIt.registerFactory(() => SantriDetailCubit(getIt()));

  getIt.registerFactory(() => AsatidzCubit(getIt()));

  getIt.registerFactory(() => AsatidzDetailCubit(getIt()));

  // Payment
  getIt.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerFactory(() => PaymentCubit(getIt(), getIt()));

  getIt.registerFactory(() => InputPaymentCubit(getIt()));

  getIt.registerFactory(() => SantriPaymentHistoryCubit(getIt()));

  getIt.registerFactory(
    () => FamilyPaymentCubit(
      familyRepository: getIt(),
      santriRepository: getIt(),
      paymentRepository: getIt(),
    ),
  );

  getIt.registerFactory(() => FinancialReportCubit(getIt(), getIt()));

  getIt.registerFactory(() => ScheduleCubit(getIt()));

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

  getIt.registerFactory(() => AsatidzSantriCubit(scheduleRepository: getIt()));

  getIt.registerFactory(
    () => SantriHomeCubit(
      santriRepository: getIt(),
      paymentRepository: getIt(),
      scheduleRepository: getIt(),
      asatidzRepository: getIt(),
      mgmtAsatidzRepository: getIt(),
      monthlyReportRepository: getIt(),
      familyRepository: getIt(),
    ),
  );

  getIt.registerFactory(() => SantriSetoranCubit(getIt()));

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

  getIt.registerFactory(() => MonthlyReportInputCubit(repository: getIt()));

  getIt.registerFactory(() => SantriMonthlyReportCubit(repository: getIt()));

  getIt.registerFactory(
    () => AdminAssessmentCubit(
      scheduleRepository: getIt(),
      reportRepository: getIt(),
      asatidzRepository: getIt(),
    ),
  );

  // Family
  getIt.registerLazySingleton(() => FamilyRepository(getIt()));

  // Kelulusan (syahadah)
  getIt.registerLazySingleton(() => KelulusanRepository(getIt()));

  getIt.registerFactory(
    () => FamilyCubit(familyRepository: getIt(), santriRepository: getIt()),
  );

  // Uji Bacaan Qur'an (recitation check)
  getIt.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instanceFor(
      region: AppConfig.current.functionsRegion,
    ),
  );
  getIt.registerLazySingleton(() => QuranLocalDataSource());
  getIt.registerLazySingleton(
    () => TranscriptionRemoteDataSource(getIt<FirebaseFunctions>()),
  );
  getIt.registerLazySingleton<RecitationRepository>(
    () => RecitationRepositoryImpl(local: getIt(), remote: getIt()),
  );
  getIt.registerFactory(() => RecitationCheckCubit(getIt()));

  // Kuis Hafalan (recitation quiz)
  getIt.registerLazySingleton(
    () => QuizEnergyRemoteDataSource(getIt<FirebaseFunctions>()),
  );
  getIt.registerLazySingleton(() => QuizSettingsStore());
  getIt.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(
      local: getIt(),
      recitation: getIt(),
      firestore: getIt(),
      auth: getIt(),
      energyRemote: getIt(),
    ),
  );
  getIt.registerFactory(() => RecitationQuizCubit(getIt(), getIt()));
  getIt.registerFactory(() => QuizLeaderboardCubit(getIt(), getIt()));
  getIt.registerFactory(() => ArenaLobbyCubit(getIt()));

  // Tahfiz Arena (shell Petualangan + Kuis + Papan Juara)
  getIt.registerFactory(
    () => ArenaCubit(
      getIt<QuizRepository>(),
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  // Petualangan Surah (surah journey)
  getIt.registerLazySingleton<SurahJourneyRepository>(
    () => SurahJourneyRepositoryImpl(
      local: getIt(),
      recitation: getIt(),
      firestore: getIt(),
      auth: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SurahJourneyCubit(getIt(), getIt<QuizRepository>()),
  );
  getIt.registerFactoryParam<SurahLessonCubit, SurahLesson, void>(
    (lesson, _) => SurahLessonCubit(getIt(), getIt<QuizRepository>(), lesson),
  );
}
