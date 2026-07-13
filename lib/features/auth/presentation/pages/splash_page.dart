import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.read<AuthCubit>().checkAuth();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthAuthenticated():
            context.goNamed(RouteNames.home);
            break;
          case AuthUnauthenticated():
            context.goNamed(RouteNames.login);
            break;
          case AuthInitial():
            break;
          case AuthLoading():
            break;
          case AuthError():
            break;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Center(
              child: Image(
                image: AssetImage(AppConfig.current.logoAsset),
                width: 150,
                height: 150,
              ),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: FutureBuilder<String>(
                  future: context.read<AuthCubit>().getVersion(),
                  builder: (context, snapshot) {
                    return Text(
                      'Version ${snapshot.data ?? ''}',
                      style: AppTextStyles.bodyBold,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
