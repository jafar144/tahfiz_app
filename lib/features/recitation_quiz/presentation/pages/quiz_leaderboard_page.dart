import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_state.dart';

/// Palet khusus papan juara.
class _LbColors {
  _LbColors._();

  // Latar gradien (biru malam → biru brand).
  static const bgTop = Color(0xFF0B1F3A);
  static const bgMid = Color(0xFF123E6B);
  static const bgBottom = Color(0xFF1E88E5);

  // Medali.
  static const gold = Color(0xFFFFC93C);
  static const goldDeep = Color(0xFFDF9A00);
  static const silver = Color(0xFFC8D3DD);
  static const silverDeep = Color(0xFF8FA3B3);
  static const bronze = Color(0xFFE0966A);
  static const bronzeDeep = Color(0xFFB05E2C);

  static Color ringFor(int rank) => switch (rank) {
        1 => gold,
        2 => silver,
        _ => bronze,
      };

  static List<Color> podiumGradient(int rank) => switch (rank) {
        1 => const [gold, goldDeep],
        2 => const [silver, silverDeep],
        _ => const [bronze, bronzeDeep],
      };
}

class QuizLeaderboardPage extends StatelessWidget {
  const QuizLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LbColors.bgTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Papan Juara'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.45, 1],
            colors: [_LbColors.bgTop, _LbColors.bgMid, _LbColors.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // Ornamen geometris islami (bintang 8 sudut) samar di latar.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _StarLatticePainter()),
              ),
            ),
            SafeArea(
              child: BlocBuilder<QuizLeaderboardCubit, QuizLeaderboardState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      // Toggle mode: Suara | Pilihan (papan terpisah).
                      _ModeTabs(
                        mode: state.mode,
                        onChanged: (m) =>
                            context.read<QuizLeaderboardCubit>().switchMode(m),
                      ),
                      Expanded(
                        child: switch (state.status) {
                          LeaderboardStatus.loading => const _Skeleton(),
                          LeaderboardStatus.error => _ErrorView(
                              message:
                                  state.errorMessage ?? 'Terjadi kesalahan.',
                              onRetry: () =>
                                  context.read<QuizLeaderboardCubit>().load(),
                            ),
                          LeaderboardStatus.loaded => _LoadedView(
                              leaderboard: state.leaderboard!,
                              currentUserId: state.currentUserId,
                            ),
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Mode toggle ──

/// Segmented toggle Suara | Pilihan (papan juara terpisah per mode).
class _ModeTabs extends StatelessWidget {
  final QuizMode mode;
  final ValueChanged<QuizMode> onChanged;

  const _ModeTabs({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            _tab(
              label: 'Suara',
              icon: Icons.mic_rounded,
              selected: mode.isVoice,
              onTap: () => onChanged(QuizMode.voice),
            ),
            _tab(
              label: 'Pilihan',
              icon: Icons.grid_view_rounded,
              selected: mode.isChoice,
              onTap: () => onChanged(QuizMode.choice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? _LbColors.bgMid : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? _LbColors.bgMid : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── Loaded ──

class _LoadedView extends StatelessWidget {
  final MonthlyLeaderboard leaderboard;
  final String? currentUserId;

  const _LoadedView({required this.leaderboard, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final entries = leaderboard.entries;
    final top3 = entries.take(3).toList();
    final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<QuizLeaderboardCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _MonthChip(monthKey: leaderboard.monthKey),
                const SizedBox(height: 14),
                const _FastabiqulKhairat(),
                const SizedBox(height: 24),
                _Podium(top3: top3, currentUserId: currentUserId),
                const SizedBox(height: 20),
                _RankSheet(
                  rest: rest,
                  isBoardEmpty: entries.isEmpty,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ),
        _MyRankBar(
          myEntry: leaderboard.myEntry,
          myRank: leaderboard.myRank,
        ),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  final String monthKey;

  const _MonthChip({required this.monthKey});

  String get _label {
    try {
      final date = DateTime.parse('$monthKey-01');
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return monthKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded,
                size: 15, color: _LbColors.gold),
            const SizedBox(width: 6),
            Text(
              'Bulan Ini • $_label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ayat motivasi kompetisi dalam kebaikan (QS. Al-Baqarah: 148).
class _FastabiqulKhairat extends StatelessWidget {
  const _FastabiqulKhairat();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '﴿ فَاسْتَبِقُوا الْخَيْرَاتِ ﴾',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _LbColors.gold,
            fontSize: 22,
            height: 1.6,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: _LbColors.gold.withValues(alpha: 0.45),
                blurRadius: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '"Berlomba-lombalah dalam kebaikan" — QS. Al-Baqarah: 148',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── Podium ──

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final String? currentUserId;

  const _Podium({required this.top3, this.currentUserId});

  LeaderboardEntry? _at(int i) => i < top3.length ? top3[i] : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSpot(
              rank: 2,
              entry: _at(1),
              blockHeight: 74,
              isMe: _at(1)?.userId == currentUserId,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumSpot(
              rank: 1,
              entry: _at(0),
              blockHeight: 104,
              isMe: _at(0)?.userId == currentUserId,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumSpot(
              rank: 3,
              entry: _at(2),
              blockHeight: 58,
              isMe: _at(2)?.userId == currentUserId,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final int rank;
  final LeaderboardEntry? entry;
  final double blockHeight;
  final bool isMe;

  const _PodiumSpot({
    required this.rank,
    required this.entry,
    required this.blockHeight,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final ring = _LbColors.ringFor(rank);
    final e = entry;
    final double avatarSize = rank == 1 ? 66 : 54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text('👑', style: TextStyle(fontSize: 26)),
          ),
        // Avatar berbingkai warna medali.
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 3),
            boxShadow: [
              BoxShadow(
                color: ring.withValues(alpha: rank == 1 ? 0.55 : 0.3),
                blurRadius: rank == 1 ? 18 : 10,
              ),
            ],
            color: Colors.white,
          ),
          child: Center(
            child: e == null
                ? Icon(Icons.person_outline_rounded,
                    color: Colors.black26, size: avatarSize * 0.5)
                : Text(
                    _initials(e.name),
                    style: TextStyle(
                      fontSize: avatarSize * 0.34,
                      fontWeight: FontWeight.w800,
                      color: _LbColors.bgMid,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        // Nama.
        Text(
          e == null ? 'Menunggu…' : (isMe ? '${e.name} (Kamu)' : e.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: e == null
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white,
            fontSize: rank == 1 ? 13.5 : 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        // Skor.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 14, color: ring),
              const SizedBox(width: 3),
              Text(
                e == null ? '—' : '${e.bestScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Balok podium.
        Container(
          height: blockHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _LbColors.podiumGradient(rank),
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: rank == 1 ? 34 : 26,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.9),
                shadows: const [
                  Shadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────── Peringkat 4-10 ──

class _RankSheet extends StatelessWidget {
  final List<LeaderboardEntry> rest;
  final bool isBoardEmpty;
  final String? currentUserId;

  const _RankSheet({
    required this.rest,
    required this.isBoardEmpty,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isBoardEmpty)
            const _EmptyBoard()
          else if (rest.isEmpty)
            const _OnlyTopThree()
          else
            ...List.generate(rest.length, (i) {
              final entry = rest[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RankTile(
                  rank: i + 4,
                  entry: entry,
                  isMe: entry.userId == currentUserId,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  const _RankTile({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nomor peringkat.
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar inisial.
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                _initials(entry.name),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nama (+ badge "Kamu").
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Kamu',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Skor.
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: _LbColors.goldDeep),
              const SizedBox(width: 3),
              Text(
                '${entry.bestScore}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 52, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'Belum ada juara bulan ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selesaikan satu sesi kuis dan jadilah\nyang pertama mengisi papan ini!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OnlyTopThree extends StatelessWidget {
  const _OnlyTopThree();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Text(
        'Peringkat 4–10 masih kosong.\nAyo rebut posisimu!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Kartu peringkatku ──

class _MyRankBar extends StatelessWidget {
  final LeaderboardEntry? myEntry;
  final int? myRank;

  const _MyRankBar({this.myEntry, this.myRank});

  @override
  Widget build(BuildContext context) {
    final e = myEntry;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_LbColors.bgMid, _LbColors.bgBottom],
                ),
              ),
              child: Center(
                child: e == null
                    ? const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 20)
                    : Text(
                        myRank != null ? '#$myRank' : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e == null ? 'Kamu belum ikut bulan ini' : 'Peringkatmu bulan ini',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    e == null
                        ? 'Mainkan kuis dan raih posisimu di papan juara!'
                        : 'Skor terbaik: ${e.bestScore} • ${e.playCount}x main',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (e != null) ...[
              const Icon(Icons.star_rounded,
                  size: 20, color: _LbColors.goldDeep),
              const SizedBox(width: 3),
              Text(
                '${e.bestScore}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Loading & error ──

class _Skeleton extends StatefulWidget {
  const _Skeleton();

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 12}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _box(150, 26, r: 999),
            const SizedBox(height: 22),
            _box(210, 22, r: 999),
            const SizedBox(height: 34),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _box(double.infinity, 130)),
                const SizedBox(width: 10),
                Expanded(child: _box(double.infinity, 180)),
                const SizedBox(width: 10),
                Expanded(child: _box(double.infinity, 110)),
              ],
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < 4; i++) ...[
              _box(double.infinity, 54),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white70),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _LbColors.bgMid,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Utilitas ──

/// Inisial nama (maks 2 huruf), mis. "Ahmad Fauzi" → "AF".
String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, math.min(2, parts.first.length)).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Ornamen latar: kisi bintang 8 sudut (motif geometri islami) samar.
class _StarLatticePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const cell = 84.0;
    const radius = 26.0;

    for (var y = cell / 2; y < size.height; y += cell) {
      // Baris diselang-seling agar terasa seperti anyaman.
      final isOffsetRow = ((y - cell / 2) / cell).round().isOdd;
      final startX = isOffsetRow ? cell : cell / 2;
      for (var x = startX; x < size.width + cell / 2; x += cell) {
        _drawStar(canvas, Offset(x, y), radius, paint);
      }
    }
  }

  /// Bintang 8 sudut = dua persegi bertumpuk, salah satunya diputar 45°.
  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
