import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_cubit.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/admin_home_page.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/admin_bottom_nav.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/admin_santri_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/admin_asatidz_page.dart';
import 'package:khoirunnasyien/features/profile/presentation/pages/admin_profile_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    AdminHomePage(),
    AdminSantriPage(),
    AdminAsatidzPage(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.read<AdminHomeCubit>().loadHome();
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
