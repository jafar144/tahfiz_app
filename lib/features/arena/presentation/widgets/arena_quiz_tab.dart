import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_cubit.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_state.dart';
import 'package:khoirunnasyien/features/arena/presentation/pages/arena_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_launch.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_curriculum.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_difficulty_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_cubit.dart';

class ArenaQuizTab extends StatelessWidget {
  const ArenaQuizTab({super.key});

  Future<void> _openPractice(BuildContext context) async {
    final cubit = context.read<ArenaCubit>();
    // Energi juga dipakai header tab Petualangan (SurahJourneyCubit) — segarkan
    // KEDUANYA saat kembali dari kuis agar angkanya tidak basi.
    final journey = context.read<SurahJourneyCubit>();
    await context.pushNamed(RouteNames.recitationQuiz);
    if (!context.mounted) return;
    await Future.wait([cubit.refresh(), journey.refresh()]);
  }

  Future<void> _openChallengeSheet(
    BuildContext context,
    ArenaState state,
  ) async {
    final cubit = context.read<ArenaCubit>();
    final journey = context.read<SurahJourneyCubit>();
    final launch = await showModalBottomSheet<QuizLaunch>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArenaColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ChallengeSheet(state: state),
    );
    if (launch == null || !context.mounted) return;
    await context.pushNamed(RouteNames.recitationQuiz, extra: launch);
    if (!context.mounted) return;
    await Future.wait([cubit.refresh(), journey.refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArenaCubit, ArenaState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mau main apa hari ini?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Asah hafalanmu lewat latihan bebas atau Tantangan harian.',
                style: TextStyle(color: Colors.white60, fontSize: 12.5),
              ),
              const SizedBox(height: 20),

              // ── Kartu LATIHAN ─────────────────────────────────────────
              _ModeCard(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4ED8), Color(0xFF0E7490)],
                ),
                icon: Icons.fitness_center_rounded,
                title: 'Latihan',
                subtitle:
                    'Bebas pilih juz, rentang hafalan, dan mode (Suara / '
                    'Pilihan). Hasil tidak dicatat — santai saja!',
                chips: const [
                  _InfoChip(icon: kEnergyIcon, label: '1 energi / sesi'),
                  _InfoChip(icon: Icons.tune_rounded, label: 'Bebas dikustom'),
                  _InfoChip(
                    icon: Icons.speed_rounded,
                    label: '3 tingkat kesulitan',
                  ),
                ],
                buttonLabel: 'Mulai Latihan',
                onPressed: () => _openPractice(context),
              ),
              const SizedBox(height: 16),

              // ── Kartu TANTANGAN ───────────────────────────────────────
              _buildChallengeCard(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(BuildContext context, ArenaState state) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9A3412), Color(0xFFB45309)],
    );

    // Profil (role + kelas) belum termuat → kartu belum bisa diketuk.
    if (state.status != ArenaStatus.ready) {
      return const _ModeCard(
        gradient: gradient,
        icon: Icons.local_fire_department_rounded,
        title: 'Tantangan',
        subtitle:
            'Soal sesuai kurikulum kelasmu, jatah terbatas tiap pekan — skor '
            'terbaik masuk papan juara sesuai tingkatan kuis.',
        chips: [],
        buttonLabel: 'Memuat…',
        onPressed: null,
      );
    }

    // Bukan santri (admin/asatidz) → kartu terkunci.
    if (!state.isSantri) {
      return _ModeCard(
        gradient: gradient,
        icon: Icons.local_fire_department_rounded,
        title: 'Tantangan',
        subtitle:
            'Khusus santri: soal sesuai kurikulum kelas, jatah terbatas tiap '
            'pekan, hasilnya masuk papan juara sesuai tingkatan kuis.',
        chips: const [
          _InfoChip(icon: Icons.lock_rounded, label: 'Khusus santri'),
        ],
        buttonLabel: 'Khusus Santri',
        onPressed: null,
      );
    }

    // Santri kelas Tahsin (atau kelas tak dikenal) → belum bisa ikut.
    if (!state.canChallenge) {
      return _ModeCard(
        gradient: gradient,
        icon: Icons.local_fire_department_rounded,
        title: 'Tantangan',
        subtitle:
            'Tantangan terbuka mulai kelas Mutawassith. Selesaikan dulu '
            'jenjang Tahsin-mu — semangat!',
        chips: const [
          _InfoChip(
            icon: Icons.school_rounded,
            label: 'Mulai kelas Mutawassith',
          ),
        ],
        buttonLabel: 'Belum Terbuka',
        onPressed: null,
      );
    }

    final bothEmpty = state.voiceQuotaEmpty && state.choiceQuotaEmpty;
    // Label sisa jatah per mode: "sisa Nx" / "habis ✓"; belum termuat → "…".
    String quotaLabel(String name, int? left) {
      if (left == null) return '$name …';
      return left > 0 ? '$name sisa ${left}x' : '$name habis ✓';
    }

    return _ModeCard(
      gradient: gradient,
      icon: Icons.local_fire_department_rounded,
      title: 'Tantangan',
      subtitle:
          'Soal mengikuti kurikulum kelasmu${state.kelas != null ? ' (${state.kelas})' : ''}. '
          'Jatah terbatas tiap pekan — skor terbaikmu masuk papan juara sesuai tingkatan kuis!',
      chips: [
        _InfoChip(
          icon: state.voiceQuotaEmpty
              ? Icons.check_circle_rounded
              : Icons.mic_rounded,
          label: quotaLabel('Suara', state.voiceChallengeLeft),
        ),
        _InfoChip(
          icon: state.choiceQuotaEmpty
              ? Icons.check_circle_rounded
              : Icons.grid_view_rounded,
          label: quotaLabel('Pilihan', state.choiceChallengeLeft),
        ),
        const _InfoChip(
          icon: Icons.speed_rounded,
          label: 'Mudah • Sedang • Sulit',
        ),
      ],
      buttonLabel: bothEmpty
          ? 'Jatah pekan ini habis — pekan depan lagi!'
          : 'Mulai Tantangan',
      onPressed: bothEmpty ? null : () => _openChallengeSheet(context, state),
    );
  }
}

// ───────────────────────────────────────────────────────────── Mode card ──

class _ModeCard extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> chips;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _ModeCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
          const SizedBox(height: 14),
          QuizButton(
            onPressed: onPressed,
            label: buttonLabel,
            color: Colors.white,
            foregroundColor: const Color(0xFF12324B),
            padding: const EdgeInsets.symmetric(vertical: 13),
            borderRadius: 14,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Challenge sheet ──

/// Lembar setelan Tantangan: pilih mode (Suara/Pilihan, yang sudah dimainkan
/// hari ini terkunci) dan cakupan kelas (kelas sendiri / turun 1 kelas bila
/// tersedia). Mengembalikan [QuizLaunch] lewat `Navigator.pop`.
class _ChallengeSheet extends StatefulWidget {
  final ArenaState state;

  const _ChallengeSheet({required this.state});

  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  late QuizMode _mode = widget.state.voiceQuotaEmpty
      ? QuizMode.choice
      : QuizMode.voice;
  QuizDifficulty _difficulty = QuizDifficulty.medium;

  /// Kelas cakupan terpilih (default: kelas sendiri).
  late String _scope = widget.state.kelas!;

  String get _ownKelas => widget.state.kelas!;

  String? get _belowKelas => QuizCurriculum.classBelow(_ownKelas);

  bool _quotaEmpty(QuizMode m) =>
      m.isVoice ? widget.state.voiceQuotaEmpty : widget.state.choiceQuotaEmpty;

  int? _quotaLeft(QuizMode m) => m.isVoice
      ? widget.state.voiceChallengeLeft
      : widget.state.choiceChallengeLeft;

  /// Subtitle opsi mode: sisa jatah pekan ini, atau keterangan default.
  String _modeSubtitle(QuizMode m, String fallback) {
    if (_quotaEmpty(m)) return 'Jatah pekan ini habis';
    final left = _quotaLeft(m);
    return left == null ? fallback : '$fallback • sisa ${left}x';
  }

  @override
  Widget build(BuildContext context) {
    final below = _belowKelas;
    final selectedTier = QuizCurriculum.leaderboardTierFor(_scope);
    final canStart = !_quotaEmpty(_mode) && selectedTier != null;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: QuizColors.gold,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Tantangan Mingguan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Jatah terbatas tiap pekan untuk tiap mode. Skor terbaik bulan '
              'ini tampil di papan juara sesuai tingkatan kuis yang dipilih.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 18),

            const QuizSectionLabel(
              icon: Icons.sports_esports_rounded,
              text: 'Mode Main',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: QuizSelectionCard(
                    icon: Icons.mic_rounded,
                    title: 'Suara',
                    subtitle: _modeSubtitle(
                      QuizMode.voice,
                      'Bacakan jawabannya · Poin ${quizMultiplierLabel(QuizDifficultyRules.modeScoreMultiplier(QuizMode.voice))}',
                    ),
                    selected: _mode.isVoice,
                    disabled: _quotaEmpty(QuizMode.voice),
                    onTap: () => setState(() => _mode = QuizMode.voice),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuizSelectionCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Pilihan',
                    subtitle: _modeSubtitle(
                      QuizMode.choice,
                      '6 opsi · 60 detik · Poin ${quizMultiplierLabel(QuizDifficultyRules.modeScoreMultiplier(QuizMode.choice))}',
                    ),
                    selected: _mode.isChoice,
                    disabled: _quotaEmpty(QuizMode.choice),
                    onTap: () => setState(() => _mode = QuizMode.choice),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const QuizSectionLabel(
              icon: Icons.speed_rounded,
              text: 'Tingkat Kesulitan',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final difficulty in QuizDifficulty.values) ...[
                  Expanded(
                    child: QuizSelectionCard(
                      icon: quizDifficultyIcon(difficulty),
                      title: difficulty.label,
                      subtitle:
                          'Poin ${quizMultiplierLabel(QuizDifficultyRules.scoreMultiplier(difficulty))}',
                      selected: _difficulty == difficulty,
                      onTap: () => setState(() => _difficulty = difficulty),
                    ),
                  ),
                  if (difficulty != QuizDifficulty.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),

            const QuizSectionLabel(
              icon: Icons.layers_rounded,
              text: 'Cakupan Soal',
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.school_rounded,
              title: 'Kelasku — $_ownKelas',
              subtitle: _scopeSubtitle(_ownKelas),
              selected: _scope == _ownKelas,
              onTap: () => setState(() => _scope = _ownKelas),
            ),
            if (below != null) ...[
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.south_rounded,
                title: 'Turun 1 kelas — $below',
                subtitle: _scopeSubtitle(below),
                selected: _scope == below,
                onTap: () => setState(() => _scope = below),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih ini bila materi kelasmu belum tuntas — skor akan masuk '
                'papan juara tingkatan kuis yang dipilih.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: QuizButton(
                label: canStart ? 'Mulai Tantangan' : 'Jatah mode ini habis',
                icon: Icons.play_arrow_rounded,
                color: QuizColors.gold,
                foregroundColor: const Color(0xFF3A2A00),
                borderRadius: 14,
                onPressed: canStart
                    ? () => Navigator.of(context).pop(
                        QuizLaunch(
                          mode: _mode,
                          difficulty: _difficulty,
                          ownKelas: _ownKelas,
                          scopeKelas: _scope,
                          tier: selectedTier,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _scopeSubtitle(String kelas) {
    final summary = _scopeSummary(kelas);
    final tier = QuizCurriculum.leaderboardTierFor(kelas);
    if (tier == null) return summary;
    return '$summary • Papan ${tier.label}';
  }

  /// Ringkasan cakupan kurikulum sebuah kelas untuk subtitle opsi.
  static String _scopeSummary(String kelas) {
    final scope = QuizCurriculum.scopeFor(kelas);
    if (scope == null) return '';
    final parts = <String>[];
    if (scope.juz.isNotEmpty) {
      parts.add('Juz ${scope.juz.join(', ')}');
    }
    if (scope.extraSurahs.isNotEmpty) {
      parts.add('+ paket surah pilihan Juz 29');
    }
    return parts.join(' ');
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? QuizColors.gold.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? QuizColors.gold : Colors.white12,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? QuizColors.gold : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: active ? QuizColors.gold : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
