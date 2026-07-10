import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/arena/presentation/widgets/arena_leaderboard_tab.dart';
import 'package:khoirunnasyien/features/arena/presentation/widgets/arena_quiz_tab.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/pages/surah_journey_page.dart';

/// Palet malam Tahfiz Arena — mengikuti gaya Petualangan Surah.
class ArenaColors {
  ArenaColors._();

  static const skyTop = Color(0xFF0B2540);
  static const skyBottom = Color(0xFF123B33);
  static const card = Color(0xFF14324A);
  static const navBar = Color(0xFF0A1F35);
}

/// Shell Tahfiz Arena ala Duolingo: top bar berisi energi, 3 tab lewat bottom
/// navigation — Petualangan Surah, Kuis (Latihan/Tantangan), Papan Juara.
class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                  children: const [
                    _JourneyTab(),
                    ArenaQuizTab(),
                    ArenaLeaderboardTab(),
                  ],
                ),
              ),
              _BottomNav(
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab peta petualangan — bungkus tipis agar IndexedStack tetap const.
class _JourneyTab extends StatelessWidget {
  const _JourneyTab();

  @override
  Widget build(BuildContext context) => const SurahJourneyView(showBack: false);
}

// ──────────────────────────────────────────────────────────── Bottom nav ──

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.index, required this.onChanged});

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
