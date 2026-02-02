import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/router/route_paths.dart';
import 'package:khoirunnasyien/features/auth/presentation/pages/login_page.dart';
import 'package:khoirunnasyien/features/auth/presentation/pages/splash_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/home_page.dart';

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
    ],
  );
}