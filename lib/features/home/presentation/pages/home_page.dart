import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/admin_home_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/santri_home_page.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/asatidz_home_page.dart';

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
            return const AdminHomePage();

          case UserRole.santri:
            return const SantriHomePage();

          case UserRole.asatidz:
            return const AsatidzHomePage();
        }
      },
    );
  }
}
