import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_setoran_cubit.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_home_page.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_setoran_page.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_profile_page.dart';

class SantriMainPage extends StatefulWidget {
  const SantriMainPage({super.key});

  @override
  State<SantriMainPage> createState() => _SantriMainPageState();
}

class _SantriMainPageState extends State<SantriMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SantriHomePage(),
    BlocProvider(
      create: (context) => getIt<SantriSetoranCubit>()..init(FirebaseAuth.instance.currentUser!.uid),
      child: const SantriSetoranPage(),
    ),
    const SantriProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
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
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Setoran',
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
