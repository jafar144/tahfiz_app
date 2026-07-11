import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_rank_reveal.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/night_loading_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_haptics.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar seremoni pasca-TANTANGAN: selama [reveal] masih null tampil halaman
/// loading "menghitung peringkat" (skor disimpan di baliknya), lalu baris
/// "Kamu" memanjat papan juara pelan-pelan menyusul teman satu per satu.
/// Tombol "Selanjutnya" baru muncul setelah animasi selesai → layar hasil.
class QuizRankRevealView extends StatelessWidget {
  final QuizRankReveal? reveal;
  final VoidCallback onContinue;

  const QuizRankRevealView({
    super.key,
    required this.reveal,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: reveal == null
          ? const NightLoadingPage(
              key: ValueKey('rank-loading'),
              title: 'Menghitung peringkatmu…',
              subtitle: 'Skormu sedang dicatat di papan juara kelas',
              icon: Icons.emoji_events_rounded,
              withBackground: false,
            )
          : _RankRevealBody(
              key: const ValueKey('rank-reveal'),
              reveal: reveal!,
              onContinue: onContinue,
            ),
    );
  }
}

class _RankRevealBody extends StatefulWidget {
  final QuizRankReveal reveal;
  final VoidCallback onContinue;

  const _RankRevealBody({super.key, required this.reveal, required this.onContinue});

  @override
  State<_RankRevealBody> createState() => _RankRevealBodyState();
}

class _RankRevealBodyState extends State<_RankRevealBody>
    with TickerProviderStateMixin {
  late final AnimationController _climb;
  late final Animation<double> _myPos;
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;

  /// True setelah panjatan selesai → tampilkan chip rayakan + tombol lanjut.
  bool _done = false;

  /// Slot terakhir yang sudah dilewati (untuk haptic per baris tersusul).
  int _lastCrossedSlot = 1 << 30;

  QuizRankReveal get reveal => widget.reveal;

  /// Slot AKHIR baris "Kamu" pada susunan papan terbaru (0-based).
  int get _endSlot => reveal.toRank - 1;

  /// Slot AWAL baris "Kamu": posisi lama; di luar papan / skor pertama →
  /// mulai satu slot di bawah daftar (masuk merangkak dari bawah layar).
  int get _startSlot => reveal.fromRank == null
      ? reveal.entries.length
      : math.min(reveal.fromRank! - 1, reveal.entries.length);

  @override
  void initState() {
    super.initState();
    final steps = math.max(1, _startSlot - _endSlot);
    // Pelan-pelan naik: ~0.65 dtk per anak tangga, total dibatasi 1–4,5 dtk.
    final totalMs = (steps * 650).clamp(1000, 4500);
    _climb = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    // Tiap anak tangga bergerak dengan easing sendiri + jeda singkat, supaya
    // terasa "menyusul satu per satu", bukan meluncur sekali jalan.
    _myPos = _climb.drive(
      TweenSequence<double>([
        for (var k = 0; k < steps; k++) ...[
          TweenSequenceItem(
            tween: Tween(
              begin: (_startSlot - k).toDouble(),
              end: (_startSlot - k - 1).toDouble(),
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            weight: 1,
          ),
          if (k < steps - 1)
            TweenSequenceItem(
              tween: ConstantTween((_startSlot - k - 1).toDouble()),
              weight: 0.4,
            ),
        ],
      ]),
    );
    _lastCrossedSlot = _startSlot;
    _climb.addListener(_onClimbTick);
    _climb.addStatusListener((status) {
      if (status == AnimationStatus.completed) _celebrate();
    });

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _pulseScale = _pulse.drive(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.06)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.06, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 2,
        ),
      ]),
    );

    // Beri napas sejenak agar santri sempat melihat posisi awalnya dulu.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _climb.forward();
    });
  }

  void _onClimbTick() {
    // Haptic ringan tiap MELEWATI satu baris (menyusul satu teman).
    final crossed = _myPos.value.floor();
    if (crossed < _lastCrossedSlot) {
      _lastCrossedSlot = crossed;
      QuizHaptics.select();
    }
  }

  void _celebrate() {
    if (_done) return;
    setState(() => _done = true);
    QuizHaptics.correct();
    _pulse.forward();
  }

  @override
  void dispose() {
    _climb.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = reveal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          children: [
            _Header(reveal: r, done: _done),
            const SizedBox(height: 14),
            Expanded(
              child: r.climbsVisibleBoard
                  ? _ClimbBoard(
                      reveal: r,
                      myPos: _myPos,
                      startSlot: _startSlot,
                      endSlot: _endSlot,
                      pulseScale: _pulseScale,
                    )
                  : _RankJumpCard(reveal: r, climb: _climb),
            ),
            const SizedBox(height: 12),
            // Tombol lanjut baru muncul setelah seremoni selesai.
            AnimatedSlide(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              offset: _done ? Offset.zero : const Offset(0, 0.6),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 380),
                opacity: _done ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_done,
                  child: SizedBox(
                    width: double.infinity,
                    child: QuizButton(
                      label: 'Selanjutnya',
                      icon: Icons.arrow_forward_rounded,
                      color: QuizColors.goldDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () {
                        QuizHaptics.tap();
                        widget.onContinue();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Judul + subjudul seremoni; chip perayaan muncul setelah panjatan selesai.
class _Header extends StatelessWidget {
  final QuizRankReveal reveal;
  final bool done;

  const _Header({required this.reveal, required this.done});

  @override
  Widget build(BuildContext context) {
    final r = reveal;
    final title = r.isNewEntry ? 'Masuk Papan Juara!' : 'Kamu Menyusul!';
    final subtitle = r.isNewEntry
        ? 'Skor pertamamu bulan ini langsung tercatat'
        : 'Skor barumu melewati ${r.overtakenCount} temanmu';
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [QuizColors.gold, QuizColors.goldDark],
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: QuizColors.gold.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        // Chip perayaan setelah sampai di posisi baru.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: done ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            scale: done ? 1 : 0.8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: QuizColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: QuizColors.gold),
              ),
              child: Text(
                'Sekarang peringkat ${reveal.toRank}! 🎉',
                style: const TextStyle(
                  color: QuizColors.gold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Papan juara beranimasi: baris "Kamu" memanjat dari [startSlot] ke [endSlot];
/// tiap baris yang tersusul bergeser turun satu slot tepat saat dilewati.
class _ClimbBoard extends StatelessWidget {
  final QuizRankReveal reveal;
  final Animation<double> myPos;
  final int startSlot;
  final int endSlot;
  final Animation<double> pulseScale;

  const _ClimbBoard({
    required this.reveal,
    required this.myPos,
    required this.startSlot,
    required this.endSlot,
    required this.pulseScale,
  });

  @override
  Widget build(BuildContext context) {
    final entries = reveal.entries;
    final n = entries.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tinggi baris menyesuaikan layar agar seluruh papan muat tanpa scroll.
        final rowExtent = (constraints.maxHeight / n).clamp(46.0, 62.0);
        final boardHeight = math.min(n * rowExtent, constraints.maxHeight);

        return Center(
          child: ClipRect(
            child: SizedBox(
              height: boardHeight,
              child: AnimatedBuilder(
                animation: myPos,
                builder: (context, _) {
                  final my = myPos.value;
                  return Stack(
                    children: [
                      // Baris teman-teman (susunan papan TERBARU, tanpa baris
                      // sendiri). Yang tersusul mulai satu slot lebih tinggi
                      // lalu turun ke tempat akhirnya saat "Kamu" melewatinya.
                      for (var f = 0; f < n; f++)
                        if (f != endSlot)
                          Positioned(
                            top: _friendSlot(f, my) * rowExtent,
                            left: 0,
                            right: 0,
                            height: rowExtent,
                            child: _BoardRow(
                              rank: _friendSlot(f, my).round() + 1,
                              entry: entries[f],
                              isMe: false,
                            ),
                          ),
                      // Baris "Kamu" digambar terakhir agar selalu di atas.
                      Positioned(
                        top: my * rowExtent,
                        left: 0,
                        right: 0,
                        height: rowExtent,
                        child: ScaleTransition(
                          scale: pulseScale,
                          child: _BoardRow(
                            rank: my.round() + 1,
                            entry: entries[endSlot],
                            isMe: true,
                            scoreDelta: _scoreDelta,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Kenaikan skor dibanding best lama (chip "+N" pada baris sendiri).
  int? get _scoreDelta {
    final prev = reveal.previousBest;
    if (prev == null || reveal.newBest <= prev) return null;
    return reveal.newBest - prev;
  }

  /// Slot tampil baris teman dengan slot AKHIR [f] saat posisiku di [my]:
  /// baris yang kususul memulai satu slot di atas (f-1) dan turun ke [f]
  /// tepat ketika posisiku melewatinya.
  double _friendSlot(int f, double my) {
    if (f < endSlot || f > startSlot) return f.toDouble(); // tak tersusul
    return f - (my - (f - 1)).clamp(0.0, 1.0);
  }
}

/// Satu baris papan juara (gaya senada tab Peringkat Arena, lebih ringkas).
class _BoardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final int? scoreDelta;

  const _BoardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    this.scoreDelta,
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
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isMe
            ? QuizColors.gold.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? QuizColors.gold : Colors.white10,
          width: isMe ? 1.4 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: QuizColors.gold.withValues(alpha: 0.25),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal, size: 21)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? QuizColors.gold.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: isMe ? QuizColors.gold : Colors.white12,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: isMe ? QuizColors.gold : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMe ? '${entry.name} (Kamu)' : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMe ? QuizColors.gold : Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (scoreDelta != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: QuizColors.correctBright.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+$scoreDelta',
                style: const TextStyle(
                  color: QuizColors.correctBright,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '${entry.bestScore}',
            style: TextStyle(
              color: isMe ? QuizColors.gold : Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'poin',
            style: TextStyle(color: Colors.white38, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

/// Varian saat posisi baru MASIH di luar papan top-10: tak ada baris teman
/// untuk dipanjat, jadi tampilkan angka peringkat yang menghitung mundur dari
/// posisi lama ke posisi baru.
class _RankJumpCard extends StatelessWidget {
  final QuizRankReveal reveal;
  final Animation<double> climb;

  const _RankJumpCard({required this.reveal, required this.climb});

  @override
  Widget build(BuildContext context) {
    final from = (reveal.fromRank ?? reveal.toRank).toDouble();
    final to = reveal.toRank.toDouble();
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: QuizColors.nightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: QuizColors.gold.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: QuizColors.gold.withValues(alpha: 0.18),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Peringkatmu sekarang',
              style: TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: climb,
              builder: (context, _) {
                final eased = Curves.easeInOutCubic.transform(climb.value);
                final rank = (from + (to - from) * eased).round();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: QuizColors.correctBright,
                      size: 30,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        color: QuizColors.gold,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              reveal.fromRank != null
                  ? 'Naik dari peringkat ${reveal.fromRank} • '
                        'skor terbaik ${reveal.newBest}'
                  : 'Skor terbaik ${reveal.newBest}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
