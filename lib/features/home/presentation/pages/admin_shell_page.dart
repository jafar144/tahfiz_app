import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/home/presentation/pages/admin_home_page.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/admin_bottom_nav.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/admin_santri_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/admin_asatidz_pages.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
