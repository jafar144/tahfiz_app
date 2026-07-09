import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_state.dart';
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

  static const _titles = ['Petualangan Surah', 'Kuis Hafalan', 'Papan Juara'];
  static const _subtitles = [
    'Belajar & taklukkan surah juz 30',
    'Latihan bebas atau Tantangan harian',
    'Juara Tantangan bulan ini per kelas',
  ];

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
              // Tab Petualangan punya top bar sendiri (Juz • XP • Energi);
              // tab lain memakai top bar Arena.
              if (_tab != 0)
                _TopBar(title: _titles[_tab], subtitle: _subtitles[_tab]),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: const [
                    // Tab 1: peta Petualangan Surah (header back disembunyikan
                    // karena Arena punya top bar sendiri — cukup progress).
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

// ─────────────────────────────────────────────────────────────── Top bar ──

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TopBar({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
              ],
            ),
          ),
          // Energi ala Duolingo di pojok kanan atas.
          BlocBuilder<ArenaCubit, ArenaState>(
            buildWhen: (p, c) =>
                p.energy != c.energy || p.energyLoading != c.energyLoading,
            builder: (context, state) {
              final energy = state.energy;
              if (energy == null) {
                return state.energyLoading
                    ? const EnergyBadgeSkeleton()
                    : const SizedBox.shrink();
              }
              return EnergyBadge(
                energy: energy,
                dark: true,
                onRefillReady: () =>
                    context.read<ArenaCubit>().refreshEnergy(),
              );
            },
          ),
        ],
      ),
    );
  }
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
