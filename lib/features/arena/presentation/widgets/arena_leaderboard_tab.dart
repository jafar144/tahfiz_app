import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_curriculum.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Tab Papan Juara: scroll tingkatan kuis di atas, toggle mode
/// Suara/Pilihan, lalu daftar peringkat Tantangan bulan berjalan (skor
/// TERBAIK per santri; direset tiap awal bulan).
class ArenaLeaderboardTab extends StatefulWidget {
  const ArenaLeaderboardTab({super.key});

  @override
  State<ArenaLeaderboardTab> createState() => _ArenaLeaderboardTabState();
}

class _ArenaLeaderboardTabState extends State<ArenaLeaderboardTab> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Arena mungkin sudah siap sebelum tab ini dibangun → muat setelah frame
    // pertama (tidak boleh emit di tengah build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final arena = context.read<ArenaCubit>().state;
      if (arena.status == ArenaStatus.ready) _initialLoad(arena);
    });
  }

  /// Default ke tingkatan cakupan kelas santri; bila tidak tersedia, gunakan
  /// tingkatan kuis pertama.
  void _initialLoad(ArenaState arena) {
    if (_initialized) return;
    _initialized = true;
    final tiers = QuizCurriculum.leaderboardTiers;
    if (tiers.isEmpty) return;
    final ownTier = QuizCurriculum.leaderboardTierFor(arena.kelas);
    final tier = ownTier ?? tiers.first;
    context.read<QuizLeaderboardCubit>().load(
      mode: QuizMode.voice,
      tierKey: tier.key,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArenaCubit, ArenaState>(
      listenWhen: (p, c) => c.status == ArenaStatus.ready,
      listener: (context, arena) => _initialLoad(arena),
      builder: (context, arena) {
        return BlocBuilder<QuizLeaderboardCubit, QuizLeaderboardState>(
          builder: (context, state) {
            final cubit = context.read<QuizLeaderboardCubit>();
            final tiers = QuizCurriculum.leaderboardTiers;
            final ownTier = QuizCurriculum.leaderboardTierFor(arena.kelas);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info reset bulanan.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restart_alt_rounded,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Skor terbaik Tantangan bulan ini — direset tiap '
                          'awal bulan (${_monthLabel(state.leaderboard?.monthKey)}).',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Scroll tingkatan kuis horizontal.
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: tiers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final tier = tiers[i];
                      final selected = tier.key == state.tierKey;
                      final isMine = tier.key == ownTier?.key;
                      return _TierChip(
                        label: tier.label,
                        selected: selected,
                        isMine: isMine,
                        onTap: () => cubit.switchTier(tier.key),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Toggle mode Suara / Pilihan.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        _ModeTab(
                          icon: Icons.mic_rounded,
                          label: 'Suara',
                          selected: state.mode.isVoice,
                          onTap: () => cubit.switchMode(QuizMode.voice),
                        ),
                        _ModeTab(
                          icon: Icons.grid_view_rounded,
                          label: 'Pilihan',
                          selected: state.mode.isChoice,
                          onTap: () => cubit.switchMode(QuizMode.choice),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Daftar peringkat.
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, QuizLeaderboardState state) {
    switch (state.status) {
      case LeaderboardStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        );
      case LeaderboardStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: Colors.white38,
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Gagal memuat papan juara.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                QuizButton(
                  label: 'Coba Lagi',
                  icon: Icons.refresh_rounded,
                  color: const Color(0xFF1C4364),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  onPressed: () => context.read<QuizLeaderboardCubit>().load(),
                ),
              ],
            ),
          ),
        );
      case LeaderboardStatus.loaded:
        final lb = state.leaderboard;
        if (lb == null || lb.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada yang menyelesaikan Tantangan\nbulan ini. '
                    'Jadilah yang pertama!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        final inTop = lb.entries.any((e) => e.userId == state.currentUserId);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            for (var i = 0; i < lb.entries.length; i++)
              _EntryTile(
                rank: i + 1,
                entry: lb.entries[i],
                isMe: lb.entries[i].userId == state.currentUserId,
              ),
            // Kartu "Kamu" bila punya skor tapi di luar top-10.
            if (!inTop && lb.myEntry != null) ...[
              const SizedBox(height: 8),
              _EntryTile(rank: lb.myRank ?? 0, entry: lb.myEntry!, isMe: true),
            ],
          ],
        );
    }
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

  static String _monthLabel(String? monthKey) {
    final now = DateTime.now();
    var year = now.year;
    var month = now.month;
    final parts = monthKey?.split('-');
    if (parts != null && parts.length == 2) {
      year = int.tryParse(parts[0]) ?? year;
      month = int.tryParse(parts[1]) ?? month;
    }
    return '${_monthNames[month - 1]} $year';
  }
}

// ─────────────────────────────────────────────────────────────── Widgets ──

class _TierChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isMine;
  final VoidCallback onTap;

  const _TierChip({
    required this.label,
    required this.selected,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? QuizColors.gold.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? QuizColors.gold : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine) ...[
              const Icon(
                Icons.person_rounded,
                size: 13,
                color: QuizColors.gold,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? QuizColors.gold : Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                  fontSize: 13,
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

class _EntryTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  const _EntryTile({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  static const _medalColors = [
    Color(0xFFFFD54F), // emas
    Color(0xFFB0BEC5), // perak
    Color(0xFFBC8A5F), // perunggu
  ];

  @override
  Widget build(BuildContext context) {
    final medal = rank >= 1 && rank <= 3 ? _medalColors[rank - 1] : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isMe
            ? QuizColors.gold.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? QuizColors.gold.withValues(alpha: 0.6) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // Nomor peringkat / medali.
          SizedBox(
            width: 34,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal, size: 24)
                : Text(
                    rank > 0 ? '$rank' : '—',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar inisial.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${entry.name} (Kamu)' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe ? QuizColors.gold : Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${entry.playCount}x main bulan ini',
                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Text(
            '${entry.bestScore}',
            style: TextStyle(
              color: isMe ? QuizColors.gold : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'poin',
            style: TextStyle(color: Colors.white38, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
