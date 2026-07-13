import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/asatidz_dashboard_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/asatidz_santri_page.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/asatidz_profile_page.dart';

class AsatidzShellPage extends StatefulWidget {
  const AsatidzShellPage({super.key});

  @override
  State<AsatidzShellPage> createState() => _AsatidzShellPageState();
}

class _AsatidzShellPageState extends State<AsatidzShellPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AsatidzDashboardPage(),
    AsatidzSantriPage(),
    AsatidzProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Santri',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
