import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_review.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/pages/quiz_review_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar rekap akhir sesi kuis (mode suara & pilihan).
class QuizResultView extends StatelessWidget {
  final QuizResult result;
  final List<QuizReviewItem> review;
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
    required this.saving,
    required this.saveError,
    this.energy,
    required this.onPlayAgain,
    this.onRefillReady,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isChoice = result.mode.isChoice;
    // Mode pilihan tak memakai energi → selalu bisa main lagi.
    final canPlay = isChoice || (energy?.canPlay ?? true);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            const Spacer(),
            Text(
              isChoice ? _gradePoints(result.totalPoints) : _grade(result.averageScore),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isChoice ? 'Total poinmu' : 'Nilai akhirmu',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            if (isChoice) ...[
              _PointsBadge(points: result.totalPoints),
              const SizedBox(height: 16),
              Text(
                '${result.passedCount} benar dari ${result.questionCount} soal',
                style: _passedTextStyle,
              ),
            ] else
              // Rekap mode suara dengan koreografi "gaming": cincin terisi skor
              // bacaan, lalu poin bonus terbang masuk & cincin terisi lagi.
              _VoiceScoreReveal(
                reading: result.averageScore,
                bonus: result.totalBonus,
                total: result.leaderboardScore,
                passedCount: result.passedCount,
                questionCount: result.questionCount,
              ),

            const SizedBox(height: 20),
            _saveStatus(context),
            const Spacer(),

            // Energi hanya relevan pada mode suara.
            if (!isChoice && energy != null && !energy!.isFull) ...[
              EnergyHint(energy: energy!, onRefillReady: onRefillReady),
              const SizedBox(height: 12),
            ],
            // Aksi utama.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canPlay ? onPlayAgain : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(canPlay
                    ? Icons.refresh_rounded
                    : Icons.hourglass_bottom_rounded),
                label: Text(
                    canPlay ? 'Main Lagi' : 'Energi habis',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            // Aksi sekunder berdampingan: Review (bila ada) + Selesai.
            Row(
              children: [
                if (review.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizReviewPage(
                              items: review, mode: result.mode),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.fact_check_rounded, size: 20),
                      label: const Text('Review',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFinish,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      foregroundColor: Colors.black54,
                      side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.18)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Selesai',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Menyimpan hasil…', style: TextStyle(color: Colors.black45)),
        ],
      );
    }
    if (saveError != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 16, color: QuizColors.missing),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Gagal menyimpan hasil',
                style: TextStyle(color: QuizColors.missing, fontSize: 12)),
          ),
        ],
      );
    }
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, size: 16, color: QuizColors.correct),
        SizedBox(width: 6),
        Text('Hasil tersimpan', style: TextStyle(color: Colors.black45)),
      ],
    );
  }

  static String _grade(int total) {
    if (total > 90) return 'Luar Biasa! 🌟';
    if (total >= 80) return 'Masyaa Allah!';
    if (total >= 60) return 'Bagus, terus berlatih!';
    return 'Ayo semangat berlatih!';
  }

  static String _gradePoints(int points) {
    if (points >= 120) return 'Luar Biasa! 🌟';
    if (points >= 80) return 'Masyaa Allah!';
    if (points >= 40) return 'Bagus, terus berlatih!';
    return 'Ayo semangat berlatih!';
  }
}

/// Badge poin besar untuk mode pilihan.
class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuizColors.gold,
            QuizColors.goldDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: QuizColors.gold.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: points),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
          const Text(
            'poin',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

const _passedTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.black54,
);

/// Rekap skor mode SUARA dengan koreografi "gaming":
///  1) cincin terisi dari 0 → nilai bacaan (warna sesuai skor),
///  2) badge "+bonus" emas terbang naik lalu terserap ke cincin,
///  3) cincin terisi lagi (bacaan → total) menjadi emas + kilau bila > 100,
///  4) rincian "Bacaan + Bonus = Total" muncul bertahap.
/// Bila tak ada bonus: cukup tahap 1 (tanpa badge & tanpa rincian).
class _VoiceScoreReveal extends StatefulWidget {
  final int reading;
  final int bonus;
  final int total;
  final int passedCount;
  final int questionCount;

  const _VoiceScoreReveal({
    required this.reading,
    required this.bonus,
    required this.total,
    required this.passedCount,
    required this.questionCount,
  });

  @override
  State<_VoiceScoreReveal> createState() => _VoiceScoreRevealState();
}

class _VoiceScoreRevealState extends State<_VoiceScoreReveal>
    with SingleTickerProviderStateMixin {
  static const double _ringSize = 180;

  // Penanda waktu koreografi (ms). Tahap 2 (bonus) hanya dipakai bila ada bonus.
  static const int _fill1End = 1000; // cincin terisi skor bacaan
  static const int _holdEnd = 1650; // jeda sebelum bonus muncul
  static const int _flyEnd = 2150; // badge bonus selesai terbang naik
  static const int _fill2End = 3150; // cincin terisi lagi (→ total)

  late final bool _hasBonus = widget.bonus > 0;
  late final int _totalMs = _hasBonus ? _fill2End : 1400;
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
  );

  @override
  void initState() {
    super.initState();
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  static double _ease(double t) =>
      Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

  // Cincin diukur dalam satuan PUTARAN: 1 putaran penuh = 100 poin. Skor bacaan
  // 0..100 → 0..1 putaran; total (bacaan + bonus) bisa > 100 → cincin berputar
  // lebih dari sekali (lap ke-2, dst).
  double get _baseFraction => (widget.reading / 100).clamp(0.0, 1.0);
  double get _totalFraction => widget.total / 100;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final baseColor = QuizColors.forScore(widget.reading);
    final overcharged = widget.total > 100;

    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final e = _ctl.value * _totalMs; // ms berjalan

        // Progres sapuan cincin & angka tengah.
        final double ringProgress;
        final double number;
        if (!_hasBonus) {
          final t = _ease(e / _fill1End);
          ringProgress = _baseFraction * t;
          number = widget.reading * t;
        } else if (e <= _fill1End) {
          final t = _ease(e / _fill1End);
          ringProgress = _baseFraction * t;
          number = widget.reading * t;
        } else if (e <= _flyEnd) {
          ringProgress = _baseFraction;
          number = widget.reading.toDouble();
        } else {
          final t = _ease((e - _flyEnd) / (_fill2End - _flyEnd));
          ringProgress = _baseFraction + (_totalFraction - _baseFraction) * t;
          number = widget.reading + (widget.total - widget.reading) * t;
        }

        // Peralihan warna angka (→ emas) & kilau overcharge saat tahap 2.
        final double goldT =
            _hasBonus && e > _flyEnd ? _ease((e - _flyEnd) / (_fill2End - _flyEnd)) : 0.0;
        final glow = overcharged ? goldT : 0.0;
        final numberColor = Color.lerp(baseColor, QuizColors.goldDark, goldT)!;
        final showPoin = _hasBonus && e > _flyEnd;

        // "Pop" kecil saat bonus menyatu ke cincin.
        final popT = _hasBonus ? ((e - _flyEnd) / 300).clamp(0.0, 1.0) : 0.0;
        final numberScale = 1 + math.sin(popT * math.pi) * 0.10;

        // Badge bonus: terbang dari bawah cincin, berhenti sejenak di atas
        // angka, lalu menyelam & mengecil masuk ke tengah (terserap).
        double badgeOpacity = 0, badgeScale = 0.6, badgeDy = 0;
        if (_hasBonus) {
          final flyT = _ease(((e - _holdEnd) / (_flyEnd - _holdEnd)).clamp(0.0, 1.0));
          final absorbT = ((e - _flyEnd) / 300).clamp(0.0, 1.0);
          badgeOpacity = flyT * (1 - absorbT);
          badgeScale = (0.6 + 0.4 * flyT) * (1 - 0.5 * absorbT);
          // +88px (bawah) → -24px (tepat di atas angka) → 0 (menyelam ke tengah).
          badgeDy = 88 * (1 - flyT) - 24 * flyT + 24 * absorbT;
        }

        final passedT = _ease(((e - 800) / 400).clamp(0.0, 1.0));
        final revealBase = _hasBonus ? 2450.0 : 1050.0;
        final revealSpan = _hasBonus ? 700.0 : 350.0;
        final reveal = ((e - revealBase) / revealSpan).clamp(0.0, 1.0);

        return Column(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: _ringSize,
                    height: _ringSize,
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: ringProgress,
                        baseFraction: _baseFraction,
                        baseColor: baseColor,
                        bonusColor: QuizColors.gold,
                        glow: glow,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: numberScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${number.round()}',
                          style: TextStyle(
                            fontSize: _ringSize * 0.30,
                            fontWeight: FontWeight.w900,
                            color: numberColor,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          showPoin ? 'poin' : 'nilai',
                          style: TextStyle(
                            fontSize: _ringSize * 0.11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasBonus)
                    Transform.translate(
                      offset: Offset(0, badgeDy),
                      child: Opacity(
                        opacity: badgeOpacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: badgeScale,
                          child: _BonusFlyBadge(bonus: widget.bonus),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: passedT,
              child: Text(
                '${widget.passedCount} dari ${widget.questionCount} soal lolos',
                style: _passedTextStyle,
              ),
            ),
            if (_hasBonus) ...[
              const SizedBox(height: 14),
              _breakdown(primary, reveal),
            ],
          ],
        );
      },
    );
  }

  /// Rincian "Bacaan + Bonus = Total" yang muncul bertahap (kiri → kanan).
  Widget _breakdown(Color primary, double reveal) {
    double sub(double a, double b) => ((reveal - a) / (b - a)).clamp(0.0, 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stat('Bacaan', widget.reading, Colors.black54, sub(0.0, 0.5)),
        _op('+', sub(0.15, 0.6)),
        _stat('Bonus', widget.bonus, QuizColors.goldDark, sub(0.25, 0.75)),
        _op('=', sub(0.4, 0.85)),
        _stat('Total', widget.total, primary, sub(0.5, 1.0), emphasize: true),
      ],
    );
  }

  Widget _op(String s, double t) => Opacity(
        opacity: t,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(s,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black38)),
        ),
      );

  Widget _stat(String label, int value, Color color, double t,
      {bool emphasize = false}) {
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: emphasize ? 24 : 19,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

/// Badge "+N" emas yang terbang masuk ke cincin (koreografi bonus).
class _BonusFlyBadge extends StatelessWidget {
  final int bonus;

  const _BonusFlyBadge({required this.bonus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuizColors.gold, QuizColors.goldDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: QuizColors.gold.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 2),
          Text(
            '+$bonus',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pelukis cincin skor "putaran": 1 putaran penuh = 100 poin.
///  • Putaran pertama: segmen warna dasar (skor bacaan) lalu sambungan emas
///    (bonus) sampai ujung poin.
///  • Bila total > 100 poin ([progress] > 1), cincin berputar lagi: putaran
///    ke-2+ digambar menimpa dengan emas lebih terang + kilau (overcharge).
class _ScoreRingPainter extends CustomPainter {
  final double progress; // satuan putaran; 1.0 = 100 poin, bisa > 1
  final double baseFraction; // batas skor bacaan (0..1) di putaran pertama
  final Color baseColor;
  final Color bonusColor; // emas putaran pertama
  final double glow; // 0..1 intensitas kilau overcharge

  /// Emas putaran ke-2+ (lebih terang agar putaran baru terlihat menimpa).
  static const Color lapColor = Color(0xFFFFD54F);

  _ScoreRingPainter({
    required this.progress,
    required this.baseFraction,
    required this.baseColor,
    required this.bonusColor,
    this.glow = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    const full = 2 * math.pi;

    Paint stroked(Color c, [double widthMul = 1]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * widthMul
      ..strokeCap = StrokeCap.round
      ..color = c;

    // Lintasan (track) samar.
    canvas.drawArc(
      rect,
      0,
      full,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = baseColor.withValues(alpha: 0.12),
    );

    // Kilau overcharge (di belakang sapuan) saat sudah berputar > 1 kali.
    if (glow > 0) {
      canvas.drawArc(
        rect,
        start,
        full,
        false,
        stroked(lapColor.withValues(alpha: 0.4 * glow), 1.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.9),
      );
    }

    // ── Putaran pertama: dasar (bacaan) + emas (bonus) ──────────────────────
    final firstLap = progress.clamp(0.0, 1.0).toDouble();
    final baseEnd = firstLap <= baseFraction ? firstLap : baseFraction;
    if (baseEnd > 0) {
      canvas.drawArc(rect, start, full * baseEnd, false, stroked(baseColor));
    }
    if (firstLap > baseFraction) {
      canvas.drawArc(rect, start + full * baseFraction,
          full * (firstLap - baseFraction), false, stroked(bonusColor));
    }

    // ── Putaran ke-2+ (menimpa, emas lebih terang) ─────────────────────────
    var remaining = progress - 1.0;
    while (remaining > 0) {
      final sweep = remaining.clamp(0.0, 1.0).toDouble();
      canvas.drawArc(rect, start, full * sweep, false, stroked(lapColor));
      remaining -= 1.0;
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress ||
      old.baseFraction != baseFraction ||
      old.baseColor != baseColor ||
      old.bonusColor != bonusColor ||
      old.glow != glow;
}
