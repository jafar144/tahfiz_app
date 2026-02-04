import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/admin_shell_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/santri_home_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/asatidz_home_page.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_cubit.dart';

import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final role = user.role;

        switch (role) {
          case UserRole.admin:
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<AdminHomeCubit>()),
                BlocProvider(create: (_) => getIt<SantriCubit>()),
                BlocProvider(create: (_) => getIt<AsatidzCubit>()),
              ],
              child: const AdminShellPage(),
            );

          case UserRole.santri:
            return const SantriHomePage();

          case UserRole.asatidz:
            return const AsatidzHomePage();
        }
      },
    );
  }
}
