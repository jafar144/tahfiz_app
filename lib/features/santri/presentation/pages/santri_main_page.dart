import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/arena/presentation/pages/arena_lobby_page.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_home_page.dart';
import 'package:khoirunnasyien/features/santri/presentation/pages/santri_profile_page.dart';

class SantriMainPage extends StatefulWidget {
  const SantriMainPage({super.key});

  @override
  State<SantriMainPage> createState() => _SantriMainPageState();
}

class _SantriMainPageState extends State<SantriMainPage> {
  int _currentIndex = 0;
  final Set<int> _initializedTabs = {0};

  Widget _pageFor(int index) => switch (index) {
    0 => const SantriHomePage(),
    1 => const ArenaLobbyPage(),
    _ => const SantriProfilePage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var index = 0; index < 3; index++)
            _initializedTabs.contains(index)
                ? _pageFor(index)
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
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
              _initializedTabs.add(index);
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
              icon: Icon(Icons.sports_esports_outlined),
              activeIcon: Icon(Icons.sports_esports_rounded),
              label: 'Arena',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
