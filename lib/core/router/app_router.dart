import 'package:go_router/go_router.dart';
import 'package:tahfiz_app/core/router/route_names.dart';
import 'package:tahfiz_app/core/router/route_paths.dart';
import 'package:tahfiz_app/features/auth/presentation/pages/login_page.dart';
import 'package:tahfiz_app/features/auth/presentation/pages/splash_page.dart';

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
    ],
  );
}