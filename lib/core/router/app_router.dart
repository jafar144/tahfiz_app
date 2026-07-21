import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/router/route_paths.dart';
import 'package:khoirunnasyien/features/auth/presentation/pages/login_page.dart';
import 'package:khoirunnasyien/features/auth/presentation/pages/splash_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/home_page.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/presentation/pages/app_config_page.dart';
import 'package:khoirunnasyien/features/app_config/presentation/widgets/app_feature_gate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';

import 'package:khoirunnasyien/features/management_santri/presentation/pages/add_santri_page.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/detail_santri_page.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/edit_santri_page.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/add_asatidz_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/detail_asatidz_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/edit_asatidz_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/payment/presentation/pages/admin_payment_history_page.dart';
import 'package:khoirunnasyien/features/payment/presentation/pages/admin_payment_page.dart';
import 'package:khoirunnasyien/features/payment/presentation/pages/input_payment_page.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/pages/financial_report_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/schedule_view_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/add_halaqah_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/halaqah_detail_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/asatidz_halaqah_detail_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/edit_halaqah_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/select_santri_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/select_asatidz_page.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/pages/syahadah_generator_page.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/pages/kelulusan_photo_list_page.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_payment_page.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_cubit.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_state.dart';
import 'package:khoirunnasyien/features/family/presentation/pages/family_list_page.dart';
import 'package:khoirunnasyien/features/family/presentation/pages/family_form_page.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/admin_assessment_page.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/monthly_report_input_page.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/monthly_report_list_page.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/santri_report_detail_page.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/santri_monthly_report_page.dart';
import 'package:khoirunnasyien/features/journey/presentation/pages/journey_page.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_cubit.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/pages/recitation_check_page.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/pages/arena_page.dart';
import 'package:khoirunnasyien/features/arena/presentation/pages/arena_stats_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_launch.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_review.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/pages/quiz_review_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/pages/recitation_quiz_page.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/halaqah_deposit_list_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/halaqah_deposit_list_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_attendance_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_deposit_history_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_setoran_page.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/pages/surah_journey_page.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/pages/surah_lesson_page.dart';

class AppRouter {
  /// Transisi khas Tahfiz Arena ala Android native: halaman baru meluncur
  /// masuk dari kanan MENIMPA halaman lama (halaman lama diam, tidak ikut
  /// bergeser); saat back, halaman atas meluncur keluar menyingkap halaman
  /// di bawahnya. Kuncinya: hanya memakai [animation] (primary) — tidak
  /// menyentuh secondaryAnimation sehingga halaman lama tak bergerak.
  static CustomTransitionPage<T> _slideOverPage<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          // Bayangan tipis di tepi agar terasa "menimpa" halaman di bawahnya.
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 24)],
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Transisi naik dari bawah (untuk halaman detail Energi & XP).
  static CustomTransitionPage<T> _slideUpPage<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  static final router = GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.appConfig,
        name: RouteNames.appConfig,
        builder: (context, state) => const AppConfigPage(),
      ),
      GoRoute(
        path: RoutePaths.addSantri,
        name: RouteNames.addSantri,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SantriCubit>(),
          child: const AddSantriPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.detailSantri,
        name: RouteNames.detailSantri,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return SantriDetailPage(
            santriId: state.pathParameters['id']!,
            readOnly: extras?['readOnly'] ?? false,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.editSantri,
        name: RouteNames.editSantri,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return BlocProvider.value(
            value: extras['cubit'] as SantriDetailCubit,
            child: EditSantriPage(santri: extras['santri'] as SantriDetail),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.addAsatidz,
        name: RouteNames.addAsatidz,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AsatidzCubit>(),
          child: const AddAsatidzPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.detailAsatidz,
        name: RouteNames.detailAsatidz,
        builder: (context, state) =>
            DetailAsatidzPage(asatidzId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.editAsatidz,
        name: RouteNames.editAsatidz,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return BlocProvider.value(
            value: extras['cubit'] as AsatidzDetailCubit,
            child: EditAsatidzPage(asatidz: extras['asatidz'] as AsatidzDetail),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.adminPayment,
        name: RouteNames.adminPayment,
        builder: (context, state) => const AdminPaymentPage(),
      ),
      GoRoute(
        path: RoutePaths.paymentHistory,
        name: RouteNames.paymentHistory,
        builder: (context, state) => const AdminPaymentHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.inputPayment,
        name: RouteNames.inputPayment,
        builder: (context, state) => const InputPaymentPage(),
      ),
      GoRoute(
        path: RoutePaths.financialReport,
        name: RouteNames.financialReport,
        builder: (context, state) => const FinancialReportPage(),
      ),
      GoRoute(
        path: RoutePaths.adminSchedule,
        name: RouteNames.adminSchedule,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ScheduleCubit>()..loadSchedule('L'),
          child: const ScheduleViewPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.addHalaqah,
        name: RouteNames.addHalaqah,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AddHalaqahCubit>(),
          child: const AddHalaqahPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.selectSantri,
        name: RouteNames.selectSantri,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final gender = extras['gender'] as String?;
          final disabledIds =
              (extras['disabledIds'] as List?)?.cast<String>() ?? [];
          final isMultiSelect = extras['isMultiSelect'] as bool? ?? false;
          final asatidzId = extras['asatidzId'] as String?;
          final isFree = extras['isFree'] as bool?;

          return BlocProvider(
            create: (_) => getIt<SantriCubit>()
              ..loadSantri(
                isActive: true,
                gender: gender,
                asatidzId: asatidzId,
                isFree: isFree,
              ),
            child: SelectSantriPage(
              genderFiltered: gender,
              initialSelection:
                  (extras['initialSelection'] as List?)?.cast<SantriEntity>() ??
                  [],
              disabledIds: disabledIds,
              isMultiSelect: isMultiSelect,
              asatidzId: asatidzId,
              isFree: isFree,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.selectAsatidz,
        name: RouteNames.selectAsatidz,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final gender = extras['gender'] as String?;
          final disabledIds =
              (extras['disabledIds'] as List?)?.cast<String>() ?? [];

          return BlocProvider(
            create: (_) =>
                getIt<AsatidzCubit>()
                  ..loadAsatidz(isActive: true, gender: gender),
            child: SelectAsatidzPage(
              genderFiltered: gender,
              initialSelectedId: extras['initialSelectedId'] as String?,
              disabledIds: disabledIds,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.detailHalaqah,
        name: RouteNames.detailHalaqah,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final halaqah = extras['halaqah'] as Halaqah;
          final sessionName = extras['sessionName'] as String? ?? 'Regular';
          final gender =
              extras['gender'] as String? ??
              'Putra'; // L/P usually but the page might expect full string or code? The page expects L/P or 'Putra'/'Putri'?
          // Let's check detail page: it handles L/P conversion. 'gender' passed from view page is from cubit which is 'L' or 'P'.

          return BlocProvider(
            create: (_) => getIt<HalaqahDetailCubit>(param1: halaqah)..init(),
            child: HalaqahDetailPage(sessionName: sessionName, gender: gender),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.detailAsatidzHalaqah,
        name: RouteNames.detailAsatidzHalaqah,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return AsatidzHalaqahDetailPage(
            teacherId: extras['teacherId'] as String,
            teacherName: extras['teacherName'] as String? ?? '-',
            gender: extras['gender'] as String? ?? 'L',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.editHalaqah,
        name: RouteNames.editHalaqah,
        builder: (context, state) {
          final cubit = state.extra as HalaqahDetailCubit;
          return BlocProvider.value(
            value: cubit,
            child: const EditHalaqahPage(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.adminSyahadah,
        name: RouteNames.adminSyahadah,
        builder: (context, state) => const SyahadahGeneratorPage(),
      ),
      GoRoute(
        path: RoutePaths.adminSyahadahPhotos,
        name: RouteNames.adminSyahadahPhotos,
        builder: (context, state) => const KelulusanPhotoListPage(),
      ),
      GoRoute(
        path: RoutePaths.santriPayment,
        name: RouteNames.santriPayment,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final startDate = extras['startDate'] as DateTime?;
          final santriId = extras['santriId'] as String?;
          return BlocProvider(
            create: (_) => getIt<SantriPaymentHistoryCubit>(),
            child: SantriPaymentPage(startDate: startDate, santriId: santriId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.santriReports,
        name: RouteNames.santriReports,
        pageBuilder: (context, state) => _slideOverPage(
          key: state.pageKey,
          child: SantriMonthlyReportPage(
            santriId: state.extra as String? ?? '',
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminFamily,
        name: RouteNames.adminFamily,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<FamilyCubit>()..loadFamilies(),
          child: const FamilyListPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminAssessment,
        name: RouteNames.adminAssessment,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AdminAssessmentCubit>(),
          child: const AdminAssessmentPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.monthlyReport,
        name: RouteNames.monthlyReport,
        builder: (context, state) => const MonthlyReportListPage(),
      ),
      GoRoute(
        path: RoutePaths.santriReportDetail,
        name: RouteNames.santriReportDetail,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return SantriReportDetailPage(
            santri: extras['santri'] as SantriEntity,
            viewOnly: extras['viewOnly'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.monthlyReportInput,
        name: RouteNames.monthlyReportInput,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final santri = extras['santri'] as SantriEntity;
          final bulan = extras['bulan'] as int;
          final tahun = extras['tahun'] as int;
          return BlocProvider(
            create: (_) =>
                MonthlyReportInputCubit(repository: getIt())
                  ..loadExisting(santri.id, bulan, tahun),
            child: MonthlyReportInputPage(
              santri: santri,
              asatidzId: extras['asatidzId'] as String,
              asatidzName: extras['asatidzName'] as String,
              bulan: bulan,
              tahun: tahun,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.santriAttendance,
        name: RouteNames.santriAttendance,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final activeHalaqah = extras['activeHalaqah'] as ActiveHalaqah;
          return BlocProvider(
            create: (_) => SantriAttendanceCubit(
              repository: getIt(),
              scheduleRepository: getIt(),
              activeHalaqah: activeHalaqah,
            )..init(),
            child: SantriAttendancePage(activeHalaqah: activeHalaqah),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.halaqahDeposits,
        name: RouteNames.halaqahDeposits,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final activeHalaqah = extras['activeHalaqah'] as ActiveHalaqah;
          return BlocProvider(
            create: (_) => HalaqahDepositListCubit(
              repository: getIt(),
              scheduleRepository: getIt(),
              activeHalaqah: activeHalaqah,
            )..loadData(),
            child: HalaqahDepositListPage(
              activeHalaqah: activeHalaqah,
              asatidzId: extras['asatidzId'] as String,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.santriSetoran,
        name: RouteNames.santriSetoran,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final activeHalaqah = extras['activeHalaqah'] as ActiveHalaqah;
          final santri = extras['santri'] as SantriEntity;
          return BlocProvider(
            create: (_) => SantriSetoranCubit(
              repository: getIt(),
              activeHalaqah: activeHalaqah,
              santri: santri,
              asatidzId: extras['asatidzId'] as String,
              asatidzName: extras['asatidzName'] as String,
            )..loadInitialData(),
            child: SantriSetoranPage(
              activeHalaqah: activeHalaqah,
              santri: santri,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.santriDepositHistory,
        name: RouteNames.santriDepositHistory,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return SantriDepositHistoryPage(
            santriId: extras['santriId'] as String,
            santriName: extras['santriName'] as String,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.journey,
        name: RouteNames.journey,
        builder: (context, state) =>
            JourneyPage(currentKelas: state.extra as String?),
      ),
      GoRoute(
        path: RoutePaths.familyForm,
        name: RouteNames.familyForm,
        builder: (context, state) {
          final existing = state.extra as FamilyWithMembers?;
          return BlocProvider(
            create: (_) => getIt<FamilyCubit>(),
            child: FamilyFormPage(existing: existing),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.recitationCheck,
        name: RouteNames.recitationCheck,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<RecitationCheckCubit>()..init(),
          child: const RecitationCheckPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.recitationQuiz,
        name: RouteNames.recitationQuiz,
        pageBuilder: (context, state) {
          // extra QuizLaunch = sesi TANTANGAN (dari Tahfiz Arena);
          // tanpa extra = sesi LATIHAN dengan layar intro biasa.
          final launch = state.extra is QuizLaunch
              ? state.extra as QuizLaunch
              : null;
          return _slideOverPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) =>
                  getIt<RecitationQuizCubit>()..init(challenge: launch),
              child: const RecitationQuizPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.quizReview,
        name: RouteNames.quizReview,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return QuizReviewPage(
            items: extras['items'] as List<QuizReviewItem>,
            mode: extras['mode'] as QuizMode,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.arena,
        name: RouteNames.arena,
        pageBuilder: (context, state) => _slideOverPage(
          key: state.pageKey,
          child: AppFeatureGate(
            feature: AppFeature.tahfizArena,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<ArenaCubit>()..load()),
                BlocProvider(create: (_) => getIt<SurahJourneyCubit>()..load()),
                BlocProvider(create: (_) => getIt<QuizLeaderboardCubit>()),
              ],
              child: const ArenaPage(),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.arenaStats,
        name: RouteNames.arenaStats,
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? const {};
          return _slideUpPage(
            key: state.pageKey,
            child: ArenaStatsPage(
              xp: extras['xp'] as int? ?? 0,
              energy: extras['energy'] as QuizEnergy?,
              focus: extras['focus'] as String? ?? 'energy',
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.surahJourney,
        name: RouteNames.surahJourney,
        pageBuilder: (context, state) => _slideOverPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<SurahJourneyCubit>()..load(),
            child: const SurahJourneyPage(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.surahLesson,
        name: RouteNames.surahLesson,
        pageBuilder: (context, state) {
          final lesson = state.extra as SurahLesson;
          return _slideOverPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => getIt<SurahLessonCubit>(param1: lesson)..init(),
              child: const SurahLessonPage(),
            ),
          );
        },
      ),
    ],
  );
}
