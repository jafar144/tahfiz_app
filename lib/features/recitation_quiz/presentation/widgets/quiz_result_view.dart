import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_review.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/pages/quiz_review_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_haptics.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

String _multiplierText(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

/// Layar rekap akhir sesi kuis (mode suara & pilihan).
///
/// [isChallenge] true → hasil TANTANGAN: status penyimpanan ditampilkan dan
/// tombol "Main Lagi" disembunyikan (jatah 1x per hari per mode). Latihan →
/// hasil tidak disimpan (status simpan disembunyikan), boleh main lagi selama
/// energi masih ada.
class QuizResultView extends StatelessWidget {
  final QuizResult result;
  final List<QuizReviewItem> review;
  final bool isChallenge;
  final bool saving;
  final String? saveError;
  final QuizEnergy? energy;
  final VoidCallback onPlayAgain;
  final VoidCallback? onRefillReady;
  final VoidCallback onFinish;

  const QuizResultView({
    super.key,
    required this.result,
    this.review = const [],
    this.isChallenge = false,
    required this.saving,
    required this.saveError,
    this.energy,
    required this.onPlayAgain,
    this.onRefillReady,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    // Latihan memakai energi di KEDUA mode (suara & pilihan).
    final canPlay = energy?.canPlay ?? true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            const Spacer(),
            Text(
              _gradePoints(result.finalScore),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            _ResultScoreReveal(
              mode: result.mode,
              difficulty: result.difficulty,
              modeMultiplier: result.modeMultiplier,
              difficultyMultiplier: result.difficultyMultiplier,
              points: result.resultPoints,
              bonus: result.totalBonus,
              finalScore: result.finalScore,
              xp: result.earnedXp,
            ),

            const SizedBox(height: 24),
            // Latihan tidak disimpan → status simpan hanya untuk Tantangan.
            if (isChallenge) _saveStatus(context),
            const Spacer(),

            if (isChallenge) ...[
              // Tantangan: 1 jatah mingguan terpakai.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tantangan selesai — skor terbaikmu masuk papan juara '
                      'kelas!',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Latihan memakai energi (kedua mode).
              if (energy != null && !energy!.isFull) ...[
                EnergyHint(
                  energy: energy!,
                  onRefillReady: onRefillReady,
                  dark: true,
                ),
                const SizedBox(height: 12),
              ],
              // Aksi utama (hanya latihan — Tantangan 1x per hari).
              SizedBox(
                width: double.infinity,
                child: QuizButton(
                  label: canPlay ? 'Main Lagi' : 'Energi habis',
                  icon: canPlay
                      ? Icons.refresh_rounded
                      : Icons.hourglass_bottom_rounded,
                  color: QuizColors.goldDark,
                  onPressed: canPlay ? onPlayAgain : null,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Aksi sekunder berdampingan: Review (bila ada) + Selesai.
            Row(
              children: [
                if (review.isNotEmpty) ...[
                  Expanded(
                    child: QuizButton(
                      label: 'Review',
                      icon: Icons.fact_check_rounded,
                      color: QuizColors.nightButton,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 12,
                      ),
                      borderRadius: 14,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              QuizReviewPage(items: review, mode: result.mode),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: QuizButton(
                    label: 'Selesai',
                    icon: Icons.check_rounded,
                    color: QuizColors.nightButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 12,
                    ),
                    borderRadius: 14,
                    onPressed: onFinish,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveStatus(BuildContext context) {
    if (saving) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          SizedBox(width: 8),
          Text('Menyimpan hasil…', style: TextStyle(color: Colors.white60)),
        ],
      );
    }
    if (saveError != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: QuizColors.missingBright,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Gagal menyimpan hasil',
              style: TextStyle(color: QuizColors.missingBright, fontSize: 12),
            ),
          ),
        ],
      );
    }
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: QuizColors.correctBright,
        ),
        SizedBox(width: 6),
        Text('Hasil tersimpan', style: TextStyle(color: Colors.white60)),
      ],
    );
  }

  static String _gradePoints(int points) {
    if (points >= 120) return 'Luar Biasa! 🌟';
    if (points >= 80) return 'Masyaa Allah!';
    if (points >= 40) return 'Bagus, terus berlatih!';
    return 'Ayo semangat berlatih!';
  }
}

/// Rekap hasil bergaya "kota" ala Duolingo: tiga tower muncul dari bawah satu
/// per satu, angka count-up, lalu tower XP berkilau sebagai penutup.
class _ResultScoreReveal extends StatefulWidget {
  final QuizMode mode;
  final QuizDifficulty difficulty;
  final double modeMultiplier;
  final double difficultyMultiplier;
  final int points;
  final int bonus;
  final int finalScore;
  final int xp;

  const _ResultScoreReveal({
    required this.mode,
    required this.difficulty,
    required this.modeMultiplier,
    required this.difficultyMultiplier,
    required this.points,
    required this.bonus,
    required this.finalScore,
    required this.xp,
  });

  @override
  State<_ResultScoreReveal> createState() => _ResultScoreRevealState();
}

class _ResultScoreRevealState extends State<_ResultScoreReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  final AudioPlayer _stagePlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  final List<bool> _stageStarted = [false, false, false, false, false];
  final List<int> _lastCounts = [0, 0, 0, 0, 0];
  DateTime _lastTickAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    unawaited(_stagePlayer.setPlayerMode(PlayerMode.lowLatency));
    unawaited(_tickPlayer.setPlayerMode(PlayerMode.lowLatency));
    _ctl.addListener(_handleFeedbackTick);
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.removeListener(_handleFeedbackTick);
    _ctl.dispose();
    unawaited(_stagePlayer.dispose());
    unawaited(_tickPlayer.dispose());
    super.dispose();
  }

  static double _ease(double t) =>
      Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

  double _interval(double begin, double end) {
    final v = _ctl.value;
    return _ease(((v - begin) / (end - begin)).clamp(0.0, 1.0));
  }

  void _handleFeedbackTick() {
    final pointsT = _interval(0.02, 0.20);
    final bonusT = _interval(0.20, 0.36);
    final modeT = _interval(0.38, 0.54);
    final difficultyT = _interval(0.56, 0.72);
    final xpT = _interval(0.76, 0.96);
    final base = widget.points + widget.bonus;
    final afterMode = (base * widget.modeMultiplier).round();

    _syncStageFeedback(0, pointsT, widget.points, 1.00);
    _syncStageFeedback(1, bonusT, widget.bonus, 1.14);
    _syncStageFeedback(2, modeT, afterMode - base, 1.20);
    _syncStageFeedback(3, difficultyT, widget.finalScore - afterMode, 1.28);
    _syncStageFeedback(4, xpT, widget.xp, 1.36);
  }

  void _syncStageFeedback(int index, double t, int value, double pitch) {
    if (t <= 0) return;
    if (!_stageStarted[index]) {
      _stageStarted[index] = true;
      if (index == 2 || index == 3) {
        QuizHaptics.correct();
      } else {
        QuizHaptics.tap();
      }
      unawaited(_playStageSound(pitch));
    }

    // Multiplier cukup satu hentakan saat kartunya meloncat. Bunyi hitung
    // berulang tetap dipakai hanya untuk poin, bonus, dan XP.
    if (index == 2 || index == 3) return;

    final count = (value * t).round();
    if (count <= _lastCounts[index]) return;
    final now = DateTime.now();
    if (now.difference(_lastTickAt).inMilliseconds < 85) return;
    _lastTickAt = now;
    _lastCounts[index] = count;
    QuizHaptics.light();
    unawaited(_playTickSound(pitch));
  }

  Future<void> _playStageSound(double pitch) async {
    try {
      await _stagePlayer.stop();
      await _stagePlayer.setPlaybackRate(pitch);
      await _stagePlayer.play(AssetSource('sounds/correct.wav'), volume: 0.78);
    } catch (_) {
      // Audio feedback opsional; jangan sampai menggagalkan layar hasil.
    }
  }

  Future<void> _playTickSound(double pitch) async {
    try {
      await _tickPlayer.stop();
      await _tickPlayer.setPlaybackRate(pitch);
      await _tickPlayer.play(AssetSource('sounds/tick.wav'), volume: 0.46);
    } catch (_) {
      // Widget test / device tanpa audio channel tetap aman.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final pointsT = _interval(0.02, 0.20);
        final bonusT = _interval(0.20, 0.36);
        final modeT = _interval(0.38, 0.54);
        final difficultyT = _interval(0.56, 0.72);
        final xpT = _interval(0.76, 0.96);
        final base = widget.points + widget.bonus;
        final afterMode = (base * widget.modeMultiplier).round();
        final baseShown = widget.points * pointsT + widget.bonus * bonusT;
        final modeExtra = (afterMode - base) * modeT;
        final difficultyExtra = (widget.finalScore - afterMode) * difficultyT;
        final shownTotal = (baseShown + modeExtra + difficultyExtra).round();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MultiplierCard(
                  label: 'MODE ${widget.mode.label.toUpperCase()}',
                  value: widget.modeMultiplier,
                  icon: widget.mode.isVoice
                      ? Icons.mic_rounded
                      : Icons.grid_view_rounded,
                  color: QuizColors.xpBlue,
                  t: modeT,
                ),
                const SizedBox(width: 10),
                _MultiplierCard(
                  label: 'TINGKAT ${widget.difficulty.label.toUpperCase()}',
                  value: widget.difficultyMultiplier,
                  icon: Icons.local_fire_department_rounded,
                  color: QuizColors.gold,
                  t: difficultyT,
                ),
              ],
            ),
            const SizedBox(height: 26),
            _ResultTotalValue(value: shownTotal),
            const SizedBox(height: 42),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth = ((width - 24) / 3).clamp(86.0, 112.0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ResultTower(
                      t: pointsT,
                      width: cardWidth,
                      value: widget.points,
                      label: 'Poin Dasar',
                      icon: Icons.star_rounded,
                      accentColor: const Color(0xFF00D084),
                    ),
                    const SizedBox(width: 8),
                    _ResultTower(
                      t: bonusT,
                      width: cardWidth,
                      value: widget.bonus,
                      label: 'Total Bonus',
                      icon: Icons.bolt_rounded,
                      accentColor: QuizColors.gold,
                    ),
                    const SizedBox(width: 8),
                    _ResultTower(
                      t: xpT,
                      width: cardWidth,
                      value: widget.xp,
                      label: 'XP Didapat',
                      icon: Icons.star_rounded,
                      accentColor: QuizColors.xpBlue,
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _MultiplierCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final double t;

  const _MultiplierCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final progress = t.clamp(0.0, 1.0);
    final jump = progress < 0.42
        ? Curves.easeOutCubic.transform((progress / 0.42).clamp(0.0, 1.0))
        : 1 -
              Curves.bounceOut.transform(
                ((progress - 0.42) / 0.58).clamp(0.0, 1.0),
              );

    return Transform.translate(
      offset: Offset(0, -11 * jump),
      child: Transform.scale(
        scale: 1 + (0.07 * jump),
        child: Container(
          width: 142,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.white.withValues(alpha: 0.06),
              color.withValues(alpha: 0.20),
              progress,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.24 + (0.58 * progress)),
              width: 1.4,
            ),
            boxShadow: progress > 0
                ? [
                    BoxShadow(
                      color: color.withValues(
                        alpha: (0.18 * progress) + (0.16 * jump),
                      ),
                      blurRadius: 14 + (8 * jump),
                      spreadRadius: jump,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14 + (0.16 * progress)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '×${_multiplierText(value)}',
                      style: TextStyle(
                        color: Color.lerp(Colors.white54, color, progress),
                        fontSize: 19,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTotalValue extends StatelessWidget {
  final int value;

  const _ResultTotalValue({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('result_total_value'),
      height: 94,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -2,
              shadows: [
                Shadow(
                  color: Color(0x5500AEEF),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTower extends StatelessWidget {
  final double t;
  final double width;
  final int value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const _ResultTower({
    required this.t,
    required this.width,
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final pop = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
    final dy = (1 - t) * 28;
    final count = (value * t).round();
    const height = 90.0;

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: 0.88 + 0.12 * pop,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(5, 7, 5, 6),
              child: Column(
                children: [
                  SizedBox(
                    height: 18,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF142531),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10242D),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: accentColor, size: 20),
                          const SizedBox(width: 5),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 23,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
