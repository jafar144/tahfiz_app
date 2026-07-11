import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

/// Halaman detail Energi & XP — dibuka dari badge header Petualangan Surah
/// dengan animasi naik dari bawah. Konten rincian (riwayat, hadiah, dsb.)
/// akan menyusul; untuk sekarang menampilkan total keduanya.
class ArenaStatsPage extends StatelessWidget {
  final int xp;
  final QuizEnergy? energy;

  /// Stat yang diketuk ('xp' / 'energy') — kartunya ditaruh paling atas.
  final String focus;

  const ArenaStatsPage({
    super.key,
    required this.xp,
    required this.energy,
    this.focus = 'energy',
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _EnergyCard(energy: energy),
      const SizedBox(height: 14),
      _XpCard(xp: xp),
    ];

    return Scaffold(
      body: JourneyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Energi & XP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bekalmu bertualang di Tahfiz Arena',
                  style: TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
                const SizedBox(height: 20),
                ...(focus == 'xp' ? cards.reversed : cards),
                const SizedBox(height: 18),
                // Placeholder konten rincian yang akan menyusul.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: QuizColors.gold,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rincian riwayat XP & energi segera hadir. '
                          'Terus kumpulkan, ya!',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                QuizButton(
                  label: 'Kembali Bertualang',
                  icon: Icons.explore_rounded,
                  color: QuizColors.goldDark,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu besar total energi: hilal + n/maks + bar + info pengisian.
class _EnergyCard extends StatelessWidget {
  final QuizEnergy? energy;

  const _EnergyCard({required this.energy});

  @override
  Widget build(BuildContext context) {
    final e = energy;
    final current = e?.current ?? 0;
    final max = e?.max ?? 15;
    final remaining = e?.resetAt?.difference(DateTime.now());

    final String info;
    if (e == null) {
      info = 'Energi belum termuat.';
    } else if (e.isFull) {
      info = 'Energi penuh — siap bertualang!';
    } else if (e.canPlay) {
      info = 'Reset mingguan dalam ${formatRefill(remaining ?? Duration.zero)}';
    } else {
      info = 'Bisa main lagi dalam ${formatRefill(remaining ?? Duration.zero)}';
    }

    return _StatCard(
      iconBg: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [QuizColors.gold, QuizColors.goldDark],
      ),
      icon: kEnergyIcon,
      label: 'ENERGI',
      value: '$current',
      valueSuffix: '/$max',
      valueColor: QuizColors.gold,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: max <= 0 ? 0 : (current / max).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(QuizColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Kartu besar total XP.
class _XpCard extends StatelessWidget {
  final int xp;

  const _XpCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      iconBg: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4FC3F7), QuizColors.xpBlue],
      ),
      icon: Icons.star_rounded,
      label: 'TOTAL XP',
      value: '$xp',
      valueSuffix: ' XP',
      valueColor: QuizColors.xpBlue,
      footer: const Text(
        'Kumpulkan XP dari test & ujian di Petualangan Surah.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Gradient iconBg;
  final IconData icon;
  final String label;
  final String value;
  final String valueSuffix;
  final Color valueColor;
  final Widget footer;

  const _StatCard({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueSuffix,
    required this.valueColor,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: journeyCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: iconBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                        children: [
                          TextSpan(
                            text: valueSuffix,
                            style: TextStyle(
                              color: valueColor.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }
}
