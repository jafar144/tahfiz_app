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
import 'package:khoirunnasyien/features/payment/presentation/pages/admin_payment_page.dart';
import 'package:khoirunnasyien/features/payment/presentation/pages/input_payment_page.dart';

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
        builder: (context, state) => SantriDetailPage(
          santriId: state.pathParameters['id']!,
        ),
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
        path: RoutePaths.inputPayment,
        name: RouteNames.inputPayment,
        builder: (context, state) => const InputPaymentPage(),
      ),
    ],
  );
}