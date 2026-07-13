import 'dart:async';
import 'dart:math' as math;

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
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${result.mode.label} • ${result.difficulty.label} • '
                'Skor ${result.finalScore} '
                '(×${_multiplierText(result.scoreMultiplier)}) • '
                'XP ×${_multiplierText(result.xpMultiplier)}',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 30),

            _ResultScoreReveal(
              points: result.resultPoints,
              bonus: result.totalBonus,
              xp: result.earnedXp,
              passedCount: result.passedCount,
              questionCount: result.questionCount,
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

const _passedTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.white70,
);

/// Rekap hasil bergaya "kota" ala Duolingo: tiga tower muncul dari bawah satu
/// per satu, angka count-up, lalu tower XP berkilau sebagai penutup.
class _ResultScoreReveal extends StatefulWidget {
  final int points;
  final int bonus;
  final int xp;
  final int passedCount;
  final int questionCount;

  const _ResultScoreReveal({
    required this.points,
    required this.bonus,
    required this.xp,
    required this.passedCount,
    required this.questionCount,
  });

  @override
  State<_ResultScoreReveal> createState() => _ResultScoreRevealState();
}

class _ResultScoreRevealState extends State<_ResultScoreReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  final AudioPlayer _stagePlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  final List<bool> _stageStarted = [false, false, false];
  final List<int> _lastCounts = [0, 0, 0];
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
    final pointsT = _interval(0.04, 0.42);
    final bonusT = _interval(0.42, 0.72);
    final xpT = _interval(0.72, 0.96);

    _syncStageFeedback(0, pointsT, widget.points, 1.00);
    _syncStageFeedback(1, bonusT, widget.bonus, 1.14);
    _syncStageFeedback(2, xpT, widget.xp, 1.30);
  }

  void _syncStageFeedback(int index, double t, int value, double pitch) {
    if (t <= 0) return;
    if (!_stageStarted[index]) {
      _stageStarted[index] = true;
      QuizHaptics.tap();
      unawaited(_playStageSound(pitch));
    }

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
        final pointsT = _interval(0.04, 0.42);
        final bonusT = _interval(0.42, 0.72);
        final xpT = _interval(0.72, 0.96);
        final textT = _interval(0.88, 1.0);
        final shownTotal = (widget.points * pointsT + widget.bonus * bonusT)
            .round();

        return Column(
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: _ResultTotalRing(
                points: widget.points,
                bonus: widget.bonus,
                pointsT: pointsT,
                bonusT: bonusT,
                shownTotal: shownTotal,
              ),
            ),
            const SizedBox(height: 52),
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
                      label: 'Total Poin',
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
            const SizedBox(height: 18),
            Opacity(
              opacity: textT,
              child: Text(
                '${widget.passedCount} dari ${widget.questionCount} soal lolos',
                style: _passedTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultTotalRing extends StatelessWidget {
  final int points;
  final int bonus;
  final double pointsT;
  final double bonusT;
  final int shownTotal;

  const _ResultTotalRing({
    required this.points,
    required this.bonus,
    required this.pointsT,
    required this.bonusT,
    required this.shownTotal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ResultRingPainter(
                points: points,
                bonus: bonus,
                pointsT: pointsT,
                bonusT: bonusT,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$shownTotal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'poin',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultRingPainter extends CustomPainter {
  final int points;
  final int bonus;
  final double pointsT;
  final double bonusT;

  const _ResultRingPainter({
    required this.points,
    required this.bonus,
    required this.pointsT,
    required this.bonusT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const start = -math.pi / 2;
    const full = 2 * math.pi;
    final stroke = size.width * 0.10;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - stroke) / 2,
    );
    Paint paint(Color color, {double alpha = 1}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: alpha);

    canvas.drawArc(rect, start, full, false, paint(Colors.white, alpha: 0.12));

    void drawTurns(double turnStart, double turns, Color color) {
      var remaining = turns;
      var cursor = turnStart;
      while (remaining > 0) {
        final sweep = remaining.clamp(0.0, 1.0).toDouble();
        canvas.drawArc(
          rect,
          start + full * (cursor % 1),
          full * sweep,
          false,
          paint(color),
        );
        remaining -= sweep;
        cursor += sweep;
      }
    }

    final pointTurns = (points * pointsT) / 100;
    final bonusTurns = (bonus * bonusT) / 100;
    drawTurns(0, pointTurns, QuizColors.correctBright);
    drawTurns(pointTurns, bonusTurns, QuizColors.gold);
  }

  @override
  bool shouldRepaint(_ResultRingPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.bonus != bonus ||
      oldDelegate.pointsT != pointsT ||
      oldDelegate.bonusT != bonusT;
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
