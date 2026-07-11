import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/widgets/arena_leaderboard_tab.dart';
import 'package:khoirunnasyien/features/arena/presentation/widgets/arena_quiz_tab.dart';
import 'package:khoirunnasyien/features/quiz_energy_admin/presentation/pages/admin_energy_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/night_loading_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/pages/surah_journey_page.dart';

class ArenaColors {
  ArenaColors._();

  static const skyTop = Color(0xFF0B2540);
  static const skyBottom = Color(0xFF123B33);
  static const card = Color(0xFF14324A);
  static const navBar = Color(0xFF0A1F35);
}

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  int _tab = 0;

  Future<void> _handleBack() async {
    if (_tab != 0) {
      setState(() => _tab = 0);
      return;
    }

    final leave = await _confirmExitArena();
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _confirmExitArena() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ArenaColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => const _ExitArenaSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select(
      (ArenaCubit cubit) => cubit.state.role == 'admin',
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        body: BlocBuilder<SurahJourneyCubit, SurahJourneyState>(
          buildWhen: (p, c) => p.status != c.status,
          builder: (context, journeyState) {
            final showJourneyLoading =
                _tab == 0 && journeyState.status == JourneyStatus.loading;

            return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ArenaColors.skyTop, ArenaColors.skyBottom],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: IndexedStack(
                            index: _tab,
                            children: [
                              const _JourneyTab(),
                              const ArenaQuizTab(),
                              const ArenaLeaderboardTab(),
                              if (isAdmin)
                                const AdminEnergyPage(embedded: true),
                            ],
                          ),
                        ),
                        _BottomNav(
                          index: _tab,
                          showAdminEnergy: isAdmin,
                          onChanged: (i) => setState(() => _tab = i),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showJourneyLoading)
                  const Positioned.fill(
                    child: NightLoadingPage(
                      title: 'Menyiapkan Petualanganmu...',
                      subtitle: 'Memuat progres, XP, dan energimu',
                      icon: Icons.explore_rounded,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExitArenaSheet extends StatelessWidget {
  const _ExitArenaSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: QuizColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: QuizColors.gold,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Keluar dari Arena?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'Kamu akan kembali ke halaman sebelumnya. Progres dan XP yang '
              'sudah tersimpan tetap aman.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: QuizButton(
                    label: 'Keluar',
                    icon: Icons.logout_rounded,
                    color: QuizColors.goldDark,
                    iconSize: 18,
                    labelFontSize: 13,
                    labelLetterSpacing: 0.4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuizButton(
                    label: 'Batal',
                    icon: Icons.close_rounded,
                    color: QuizColors.nightButton,
                    foregroundColor: Colors.white,
                    iconSize: 18,
                    labelFontSize: 13,
                    labelLetterSpacing: 0.4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyTab extends StatelessWidget {
  const _JourneyTab();

  @override
  Widget build(BuildContext context) => const SurahJourneyView(showBack: false);
}

class _BottomNav extends StatelessWidget {
  final int index;
  final bool showAdminEnergy;
  final ValueChanged<int> onChanged;

  const _BottomNav({
    required this.index,
    required this.showAdminEnergy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.navBar,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Petualangan',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                icon: Icons.videogame_asset_rounded,
                label: 'Kuis',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Peringkat',
                selected: index == 2,
                onTap: () => onChanged(2),
              ),
              if (showAdminEnergy)
                _NavItem(
                  icon: Icons.bolt_rounded,
                  label: 'Energi Santri',
                  selected: index == 3,
                  onTap: () => onChanged(3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? QuizColors.gold : Colors.white38;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? QuizColors.gold.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
