import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/router/route_paths.dart';
import 'package:khoirunnasyien/features/auth/presentation/pages/login_page.dart';
import 'package:khoirunnasyien/features/auth/presentation/pages/splash_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/home_page.dart';
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
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/schedule_view_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/schedule_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/add_halaqah_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/halaqah_detail_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/edit_halaqah_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/select_santri_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/select_asatidz_page.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/pages/syahadah_generator_page.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_payment_page.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_cubit.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_state.dart';
import 'package:khoirunnasyien/features/family/presentation/pages/family_list_page.dart';
import 'package:khoirunnasyien/features/family/presentation/pages/family_form_page.dart';

class AppRouter {

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
        builder: (context, state) => DetailAsatidzPage(
          asatidzId: state.pathParameters['id']!,
        ),
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
          final disabledIds = (extras['disabledIds'] as List?)?.cast<String>() ?? [];
          final isMultiSelect = extras['isMultiSelect'] as bool? ?? false;
          
          return BlocProvider(
            create: (_) => getIt<SantriCubit>()..loadSantri(
              isActive: true,
              gender: gender,
            ),
            child: SelectSantriPage(
              genderFiltered: gender,
              initialSelection: (extras['initialSelection'] as List?)?.cast<SantriEntity>() ?? [],
              disabledIds: disabledIds,
              isMultiSelect: isMultiSelect,
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
          final disabledIds = (extras['disabledIds'] as List?)?.cast<String>() ?? [];

          return BlocProvider(
            create: (_) => getIt<AsatidzCubit>()..loadAsatidz(
              isActive: true,
              gender: gender,
            ),
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
           final gender = extras['gender'] as String? ?? 'Putra'; // L/P usually but the page might expect full string or code? The page expects L/P or 'Putra'/'Putri'?
           // Let's check detail page: it handles L/P conversion. 'gender' passed from view page is from cubit which is 'L' or 'P'.
           
           return BlocProvider(
             create: (_) => getIt<HalaqahDetailCubit>(param1: halaqah)..init(),
             child: HalaqahDetailPage(
               sessionName: sessionName,
               gender: gender,
             ),
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
        path: RoutePaths.adminFamily,
        name: RouteNames.adminFamily,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<FamilyCubit>()..loadFamilies(),
          child: const FamilyListPage(),
        ),
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
    ],
  );
}