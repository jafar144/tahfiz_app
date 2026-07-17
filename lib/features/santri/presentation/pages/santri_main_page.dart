import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/feature_access_policy.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_cubit.dart';
import 'package:khoirunnasyien/features/app_config/presentation/widgets/feature_unavailable_page.dart';
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

  Widget _pageFor(int index, AppFeatureAccess arenaAccess) => switch (index) {
    0 => const SantriHomePage(),
    1 =>
      arenaAccess == AppFeatureAccess.enabled
          ? const ArenaLobbyPage()
          : const FeatureUnavailablePage(featureName: 'Tahfiz Arena'),
    _ => const SantriProfilePage(),
  };

  @override
  Widget build(BuildContext context) {
    final configState = context.watch<AppConfigCubit>().state;
    final arenaAccess = resolveAppFeatureAccess(
      config: configState.config,
      feature: AppFeature.tahfizArena,
      role: UserRole.santri,
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var index = 0; index < 3; index++)
            _initializedTabs.contains(index)
                ? _pageFor(index, arenaAccess)
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
