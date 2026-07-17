import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_lobby_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_lobby_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_tier.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_curriculum.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_cubit.dart';

class ArenaLobbyPage extends StatelessWidget {
  const ArenaLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ArenaLobbyCubit>()..loadMode(),
      child: const _ArenaLobbyView(),
    );
  }
}

class _ArenaLobbyView extends StatefulWidget {
  const _ArenaLobbyView();

  @override
  State<_ArenaLobbyView> createState() => _ArenaLobbyViewState();
}

class _ArenaLobbyViewState extends State<_ArenaLobbyView> {
  static const _nightTop = Color(0xFF0B2540);
  static const _card = Color(0xFF14324A);

  PageController? _pageController;
  int _pageIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pageController != null) return;

    final tiers = QuizCurriculum.leaderboardTiers;
    final kelas = context.read<SantriHomeCubit>().state.santri?.kelas;
    final ownTier = QuizCurriculum.leaderboardTierFor(kelas);
    final ownIndex = tiers.indexWhere((tier) => tier.key == ownTier?.key);
    _pageIndex = ownIndex < 0 ? 0 : ownIndex;
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiers = QuizCurriculum.leaderboardTiers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17212B),
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: const Text(
          'Tahfiz Arena',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _nightTop,
          backgroundColor: Colors.white,
          onRefresh: () => context.read<ArenaLobbyCubit>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<ArenaLobbyCubit, ArenaLobbyState>(
                  builder: (context, state) =>
                      _buildLeaderboard(context, state, tiers),
                ),
                const SizedBox(height: 18),
                _buildHero(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF164E72), Color(0xFF0F766E)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Stack(
          children: [
            const Positioned(right: -24, top: -32, child: _GlowOrb(size: 120)),
            const Positioned(left: 92, bottom: -46, child: _GlowOrb(size: 92)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: QuizColors.gold,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tahfiz Arena',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Petualangan • Kuis • Peringkat',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  QuizButton(
                    label: 'Masuk Arena',
                    icon: Icons.play_arrow_rounded,
                    color: QuizColors.gold,
                    foregroundColor: const Color(0xFF3A2A00),
                    borderRadius: 15,
                    onPressed: () => context.pushNamed(RouteNames.arena),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(
    BuildContext context,
    ArenaLobbyState state,
    List<QuizTier> tiers,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: QuizColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: QuizColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: state.status != ArenaLobbyStatus.loading,
                      tooltip: 'Pilih bulan',
                      color: Colors.white,
                      elevation: 8,
                      position: PopupMenuPosition.under,
                      onSelected: (monthKey) =>
                          context.read<ArenaLobbyCubit>().loadMonth(monthKey),
                      itemBuilder: (context) => [
                        for (final monthKey in arenaLobbyMonthKeys())
                          PopupMenuItem<String>(
                            value: monthKey,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _monthLabel(monthKey),
                                    style: const TextStyle(
                                      color: Color(0xFF17212B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (monthKey == state.monthKey)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, right: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _monthLabel(state.monthKey),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white60,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ModeSelector(
            mode: state.mode,
            enabled: state.status != ArenaLobbyStatus.loading,
            onChanged: (mode) => context.read<ArenaLobbyCubit>().loadMode(mode),
          ),
          const SizedBox(height: 10),
          if (state.status == ArenaLobbyStatus.loading)
            const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: QuizColors.gold),
              ),
            )
          else if (state.status == ArenaLobbyStatus.error)
            SizedBox(
              height: 250,
              child: _LeaderboardError(
                message: state.errorMessage ?? 'Gagal memuat leaderboard.',
                onRetry: () => context.read<ArenaLobbyCubit>().retry(),
              ),
            )
          else if (tiers.isEmpty)
            const SizedBox(
              height: 250,
              child: Center(
                child: Text(
                  'Tingkatan kuis belum tersedia.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: tiers.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) {
                  final tier = tiers[index];
                  return _LeaderboardPage(
                    tierLabel: tier.label,
                    leaderboard: state.leaderboards[tier.key],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < tiers.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _pageIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _pageIndex ? QuizColors.gold : Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String _monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts.isNotEmpty ? int.tryParse(parts.first) : null;
    final month = parts.length == 2 ? int.tryParse(parts.last) : null;
    if (year == null || month == null || month < 1 || month > 12) {
      return monthKey;
    }
    return '${_monthNames[month - 1]} $year';
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;

  const _GlowOrb({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        gradient: RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final QuizMode mode;
  final bool enabled;
  final ValueChanged<QuizMode> onChanged;

  const _ModeSelector({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _ModeItem(
            icon: Icons.mic_rounded,
            label: 'Suara',
            selected: mode.isVoice,
            onTap: enabled ? () => onChanged(QuizMode.voice) : null,
          ),
          _ModeItem(
            icon: Icons.grid_view_rounded,
            label: 'Pilihan',
            selected: mode.isChoice,
            onTap: enabled ? () => onChanged(QuizMode.choice) : null,
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? QuizColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? const Color(0xFF3A2A00) : Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF3A2A00) : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardPage extends StatelessWidget {
  final String tierLabel;
  final MonthlyLeaderboard? leaderboard;

  const _LeaderboardPage({required this.tierLabel, this.leaderboard});

  @override
  Widget build(BuildContext context) {
    final entries = leaderboard?.entries ?? const <LeaderboardEntry>[];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 15,
                color: QuizColors.gold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tierLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          const Expanded(child: _EmptyLeaderboard())
        else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _WinnerSpot(
                    rank: 2,
                    entry: entries.length > 1 ? entries[1] : null,
                    color: Color(0xFFB0BEC5),
                    podiumHeight: 48,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _WinnerSpot(
                    rank: 1,
                    entry: entries.first,
                    color: Color(0xFFFFD54F),
                    podiumHeight: 68,
                    champion: true,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _WinnerSpot(
                    rank: 3,
                    entry: entries.length > 2 ? entries[2] : null,
                    color: Color(0xFFBC8A5F),
                    podiumHeight: 38,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WinnerSpot extends StatelessWidget {
  final int rank;
  final LeaderboardEntry? entry;
  final Color color;
  final double podiumHeight;
  final bool champion;

  const _WinnerSpot({
    required this.rank,
    required this.entry,
    required this.color,
    required this.podiumHeight,
    this.champion = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry?.name.trim() ?? '';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (champion)
          Icon(Icons.emoji_events_rounded, size: 20, color: color)
        else
          const SizedBox(height: 20),
        Container(
          width: champion ? 50 : 44,
          height: champion ? 50 : 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: entry == null ? 0.08 : 0.18),
            border: Border.all(
              color: color.withValues(alpha: entry == null ? 0.20 : 0.85),
              width: champion ? 2 : 1.5,
            ),
          ),
          child: Text(
            initial,
            style: TextStyle(
              color: entry == null ? Colors.white24 : Colors.white,
              fontSize: champion ? 18 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 30,
          child: Text(
            entry == null ? 'Belum ada' : name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: entry == null ? Colors.white30 : Colors.white,
              fontSize: champion ? 11.5 : 10.5,
              height: 1.15,
              fontWeight: champion ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          entry == null ? '—' : '${entry!.bestScore} poin',
          style: TextStyle(
            color: entry == null ? Colors.white24 : color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: podiumHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: entry == null ? 0.08 : 0.30),
                color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: 0.55)),
            ),
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              color: color.withValues(alpha: entry == null ? 0.25 : 0.95),
              fontSize: champion ? 27 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 9),
          const Text(
            'Belum ada pemenang pada tingkatan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LeaderboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 38),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba Lagi'),
            style: TextButton.styleFrom(foregroundColor: QuizColors.gold),
          ),
        ],
      ),
    );
  }
}
