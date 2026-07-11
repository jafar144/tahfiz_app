import 'dart:async';

import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';

/// Palet warna khusus kuis (gamifikasi, tetap selaras tema app).
class QuizColors {
  QuizColors._();

  static const gold = Color(0xFFF6A609);
  static const goldDark = Color(0xFFB9770B);
  static const correct = Color(0xFF2E7D32);
  static const wrong = Color(0xFFE65100);
  static const missing = Color(0xFFC62828);
  static const extra = Colors.blueGrey;

  // ── Palet "malam islami" (samakan dengan Petualangan Surah / Arena) ──
  static const nightTop = Color(0xFF0B2540);
  static const nightBottom = Color(0xFF123B33);
  static const nightCard = Color(0xFF14324A);

  /// Permukaan tombol netral di atas latar malam (sedikit lebih terang dari
  /// kartu agar "bibir" QuizButton tetap terlihat).
  static const nightButton = Color(0xFF1C4364);

  // Varian cerah untuk teks/aksen di atas latar gelap.
  static const correctBright = Color(0xFF34D399);
  static const missingBright = Color(0xFFFF8A80);
  static const xpBlue = Color(0xFF1CB0F6);

  /// Warna berdasarkan persentase skor.
  static Color forScore(int pct) {
    if (pct > 90) return correct;
    if (pct >= 80) return gold;
    return missing;
  }
}

/// Bungkus anak layout AnimatedSwitcher dengan [Positioned.fill] TANPA
/// menghilangkan identitasnya: key Positioned diturunkan dari key anak
/// (KeyedSubtree unik buatan AnimatedSwitcher). Tanpa ini, saat transisi
/// selesai dan layar lama dibuang, Stack mencocokkan ulang berdasarkan INDEKS
/// → subtree layar baru ikut dibongkar-pasang dan seluruh State-nya (mis.
/// AnimationController layar hasil) tereset — animasi tampak "tersendat lalu
/// mengulang".
Positioned keyedFill(Widget child) => Positioned.fill(
  key: child.key == null ? null : ValueKey(child.key),
  child: child,
);

/// Pergantian soal ala Duolingo: soal & jawaban lama menggeser keluar ke kiri
/// sementara soal baru masuk dari kanan. Hanya membungkus area soal+jawaban —
/// timer/poin di luar tetap diam. [index] harus berubah tiap ganti soal agar
/// animasi terpicu; perubahan lain dalam soal yang sama (mis. warna opsi saat
/// terkunci) tidak ikut beranimasi karena key-nya tetap.
class QuestionSlideSwitcher extends StatelessWidget {
  final int index;
  final Widget child;

  const QuestionSlideSwitcher({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 340),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Soal masuk (key = index terkini) meluncur dari kanan; soal lama
          // (key lama) meluncur keluar ke kiri.
          final incoming = child.key == ValueKey(index);
          final begin = incoming ? const Offset(1, 0) : const Offset(-1, 0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        // Beri kedua kartu ukuran penuh agar konten ber-Expanded (mis. daftar
        // opsi yang mengisi sisa layar) tetap punya tinggi terikat saat digeser.
        layoutBuilder: (currentChild, previousChildren) => Stack(
          children: [
            for (final c in previousChildren) keyedFill(c),
            if (currentChild != null) keyedFill(currentChild),
          ],
        ),
        child: KeyedSubtree(key: ValueKey(index), child: child),
      ),
    );
  }
}

/// Peralihan ke/dari layar Soal Bonus dengan gaya "menimpa": hanya lapisan
/// bonus yang bergerak vertikal & selalu berada di atas, sedangkan layar soal
/// biasa diam. Masuk → bonus naik dari bawah menutupi; keluar → bonus turun
/// keluar menyingkap soal berikutnya di bawahnya. [showBonus] menandai layar
/// bonus sedang tampil.
class BonusCoverSwitcher extends StatelessWidget {
  final bool showBonus;
  final Widget child;

  const BonusCoverSwitcher({
    super.key,
    required this.showBonus,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Hanya lapisan SOAL BONUS yang bergerak; layar soal biasa selalu diam.
        // Masuk → bonus naik dari bawah menutupi; keluar → bonus turun keluar
        // menyingkap soal berikutnya yang sudah diam di bawahnya (saat keluar,
        // animasi lapisan bonus berjalan mundur sehingga bergeser ke bawah).
        final isBonusLayer = child.key == const ValueKey(true);
        if (!isBonusLayer) return child;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        // Lapisan bonus wajib selalu di ATAS agar terlihat menimpa (saat masuk)
        // dan menyingkap (saat keluar). Saat masuk, bonus = layar baru
        // (current); saat keluar, bonus = layar lama (previous).
        final prev = [for (final c in previousChildren) keyedFill(c)];
        final curr = currentChild == null
            ? const <Widget>[]
            : [keyedFill(currentChild)];
        return Stack(
          children: showBonus ? [...prev, ...curr] : [...curr, ...prev],
        );
      },
      child: KeyedSubtree(key: ValueKey(showBonus), child: child),
    );
  }
}

/// Cincin skor beranimasi dengan angka persentase di tengah.
class ScoreRing extends StatelessWidget {
  final int percent;
  final double size;
  final Color? color;
  final String? caption;
  final Color captionColor;

  const ScoreRing({
    super.key,
    required this.percent,
    this.size = 140,
    this.color,
    this.caption,
    this.captionColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? QuizColors.forScore(percent);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: size * 0.09,
                  strokeCap: StrokeCap.round,
                  backgroundColor: ringColor.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation(ringColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.bold,
                      color: ringColor,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    caption ?? '%',
                    style: TextStyle(
                      fontSize: size * 0.12,
                      color: captionColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bar progres bersegmen: satu segmen per soal.
class SegmentedProgress extends StatelessWidget {
  final int total;
  final int currentIndex; // 0-based
  final List<int> doneScores; // skor soal-soal yang sudah selesai

  const SegmentedProgress({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.doneScores,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < doneScores.length
                    ? QuizColors.forScore(doneScores[i])
                    : (i == currentIndex
                          ? primary
                          : primary.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Kartu menampilkan teks ayat prompt (buta — tanpa nama surah / nomor).
/// [dark] = tampil di atas latar malam (kartu gelap, teks putih).
class PromptAyahCard extends StatelessWidget {
  final String text;
  final bool dark;

  const PromptAyahCard({super.key, required this.text, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: dark ? QuizColors.nightCard : null,
        gradient: dark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.06),
                  scheme.primary.withValues(alpha: 0.02),
                ],
              ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.16)
              : scheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'QuranHafs',
          fontSize: 23,
          height: 1.7,
          color: dark ? Colors.white : const Color(0xFF212121),
        ),
      ),
    );
  }
}

/// Teks Arab jawaban dengan pewarnaan koreksi per kata (dari [WordDiff]).
class CorrectionText extends StatelessWidget {
  final List<WordDiff> diffs;
  final double fontSize;

  const CorrectionText({super.key, required this.diffs, this.fontSize = 26});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final d in diffs) {
      switch (d.status) {
        case WordStatus.correct:
          spans.add(
            TextSpan(
              text: '${d.referenceWordDisplay ?? d.referenceWord ?? ''} ',
              style: const TextStyle(color: QuizColors.correct),
            ),
          );
        case WordStatus.wrong:
          spans.add(
            TextSpan(
              text: '${d.referenceWordDisplay ?? d.referenceWord ?? ''} ',
              style: const TextStyle(
                color: QuizColors.wrong,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
                decorationColor: QuizColors.wrong,
              ),
            ),
          );
        case WordStatus.missing:
          spans.add(
            TextSpan(
              text: '${d.referenceWordDisplay ?? d.referenceWord ?? ''} ',
              style: const TextStyle(
                color: QuizColors.missing,
                decoration: TextDecoration.lineThrough,
                decorationColor: QuizColors.missing,
              ),
            ),
          );
        case WordStatus.extra:
          final w = d.spokenWord ?? '';
          if (w.isEmpty) continue;
          spans.add(
            TextSpan(
              text: '$w ',
              style: const TextStyle(
                color: QuizColors.extra,
                decoration: TextDecoration.underline,
                decorationColor: QuizColors.extra,
              ),
            ),
          );
      }
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'QuranHafs',
          fontSize: fontSize,
          height: 1.9,
        ),
      ),
    );
  }
}

/// Legenda singkat warna koreksi.
class CorrectionLegend extends StatelessWidget {
  const CorrectionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _LegendDot(color: QuizColors.correct, label: 'Benar'),
        _LegendDot(color: QuizColors.wrong, label: 'Salah'),
        _LegendDot(color: QuizColors.missing, label: 'Kelewat'),
        _LegendDot(color: QuizColors.extra, label: 'Tambahan'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

/// Ikon satu unit energi: bulan sabit (hilal) — nuansa game tapi islami.
const IconData kEnergyIcon = Icons.nightlight_round;

/// Format sisa waktu menuju reset kuota jadi ringkas: "3hr 4j", "2j 15m",
/// "40m", "segera".
String formatRefill(Duration d) {
  if (d.inSeconds <= 0) return 'segera';
  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  if (days > 0) return '${days}hr ${h}j';
  if (d.inHours > 0) return '${d.inHours}j ${m}m';
  if (m > 0) return '${m}m';
  return '${d.inSeconds}d';
}

/// Tampilkan bottom sheet informasi kenapa kuis tidak bisa dimulai.
Future<void> showQuizBlockSheet(BuildContext context, QuizBlockReason reason) {
  final ({IconData icon, Color color, String title, String message})
  info = switch (reason) {
    QuizBlockReason.busy => (
      icon: Icons.groups_rounded,
      color: QuizColors.gold,
      title: 'Kuis sedang dipakai',
      message:
          'Sedang ada yang bermain kuis. Kuis hanya bisa dimainkan satu '
          'orang dalam satu waktu — silakan tunggu sebentar lalu coba lagi.',
    ),
    QuizBlockReason.whisperLimit => (
      icon: Icons.hourglass_top_rounded,
      color: QuizColors.wrong,
      title: 'Kuis sedang istirahat',
      message:
          'Kuota pemeriksaan bacaan sedang penuh. Silakan coba lagi beberapa '
          'saat lagi, ya.',
    ),
    QuizBlockReason.noEnergy => (
      icon: kEnergyIcon,
      color: QuizColors.missing,
      title: 'Energi minggu ini habis',
      message:
          'Energi direset tiap awal pekan. Kamu juga bisa meminta energi '
          'tambahan ke ustadz/admin.',
    ),
    QuizBlockReason.challengeLimit => (
      icon: Icons.event_repeat_rounded,
      color: QuizColors.gold,
      title: 'Jatah Tantangan habis',
      message:
          'Kuota Tantangan mode ini untuk minggu ini sudah terpakai semua. '
          'Kembali lagi pekan depan, ya!',
    ),
    QuizBlockReason.unknown => (
      icon: Icons.error_outline_rounded,
      color: QuizColors.missing,
      title: 'Belum bisa dimulai',
      message: 'Terjadi kendala saat memulai kuis. Silakan coba lagi.',
    ),
  };

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: QuizColors.nightCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: info.color.withValues(alpha: 0.18),
              ),
              child: Icon(info.icon, color: info.color, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              info.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              info.message,
              style: const TextStyle(fontSize: 13.5, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: QuizButton(
                label: 'Mengerti',
                color: QuizColors.goldDark,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Placeholder abu-abu berdenyut untuk lencana energi selama dimuat.
class EnergyBadgeSkeleton extends StatefulWidget {
  const EnergyBadgeSkeleton({super.key});

  @override
  State<EnergyBadgeSkeleton> createState() => _EnergyBadgeSkeletonState();
}

class _EnergyBadgeSkeletonState extends State<EnergyBadgeSkeleton>
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.85).animate(_c),
      child: Container(
        width: 58,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Lencana energi ringkas untuk AppBar: hilal + "n/maks".
///
/// Diketuk → memunculkan info pengisian ("+1 energi dalam 3j 54m"). Berdenyut
/// di latar untuk memuat ulang energi ([onRefillReady]) saat waktunya tiba.
/// [dark] = tampil di atas latar gelap (mis. top bar Tahfiz Arena).
class EnergyBadge extends StatefulWidget {
  final QuizEnergy energy;
  final VoidCallback? onRefillReady;
  final bool dark;

  const EnergyBadge({
    super.key,
    required this.energy,
    this.onRefillReady,
    this.dark = false,
  });

  @override
  State<EnergyBadge> createState() => _EnergyBadgeState();
}

class _EnergyBadgeState extends State<EnergyBadge> {
  Timer? _timer;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _ensureTimer();
  }

  @override
  void didUpdateWidget(EnergyBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.energy != widget.energy) {
      _notified = false;
      _ensureTimer();
    }
  }

  void _ensureTimer() {
    _timer?.cancel();
    if (widget.energy.isFull) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final t = widget.energy.resetAt;
      if (!_notified && t != null && DateTime.now().isAfter(t)) {
        _notified = true;
        widget.onRefillReady?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showInfo() {
    final e = widget.energy;
    final box = context.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlayBox.size,
    );

    final String info;
    if (e.isFull) {
      info = 'Energi penuh';
    } else {
      final remaining =
          e.resetAt?.difference(DateTime.now()) ?? Duration.zero;
      final label = e.canPlay ? 'reset mingguan dalam' : 'Bisa main lagi dalam';
      info = '$label ${formatRefill(remaining)}';
    }

    showMenu<void>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<void>(
          enabled: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kEnergyIcon, size: 16, color: QuizColors.goldDark),
              const SizedBox(width: 8),
              Text(
                '${e.current}/${e.max}  •  $info',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.energy;
    final empty = !e.canPlay;
    final color = empty
        ? (widget.dark ? const Color(0xFFFF8A80) : QuizColors.missing)
        : (widget.dark ? QuizColors.gold : QuizColors.goldDark);
    return InkWell(
      onTap: _showInfo,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: widget.dark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: widget.dark
              ? Border.all(color: color.withValues(alpha: 0.45))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kEnergyIcon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              '${e.current}/${e.max}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: color),
          ],
        ),
      ),
    );
  }
}

/// Hint energi satu-baris yang berdenyut (untuk layar tanpa scroll, mis. hasil).
/// Menampilkan hitung mundur pengisian; memanggil [onRefillReady] saat terlewati.
class EnergyHint extends StatefulWidget {
  final QuizEnergy energy;
  final VoidCallback? onRefillReady;

  /// True bila tampil di atas latar malam (teks terang).
  final bool dark;

  const EnergyHint({
    super.key,
    required this.energy,
    this.onRefillReady,
    this.dark = false,
  });

  @override
  State<EnergyHint> createState() => _EnergyHintState();
}

class _EnergyHintState extends State<EnergyHint> {
  Timer? _timer;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _ensureTimer();
  }

  @override
  void didUpdateWidget(EnergyHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.energy != widget.energy) {
      _notified = false;
      _ensureTimer();
    }
  }

  void _ensureTimer() {
    _timer?.cancel();
    if (widget.energy.isFull) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        final t = widget.energy.resetAt;
        if (!_notified && t != null && DateTime.now().isAfter(t)) {
          _notified = true;
          widget.onRefillReady?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.energy;
    if (e.isFull) return const SizedBox.shrink();
    final empty = !e.canPlay;
    final remaining = e.resetAt?.difference(DateTime.now()) ?? Duration.zero;
    final label = empty ? 'Bisa main lagi dalam' : 'Energi reset dalam';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          kEnergyIcon,
          size: 15,
          color: empty
              ? (widget.dark ? QuizColors.missingBright : QuizColors.missing)
              : (widget.dark ? QuizColors.gold : QuizColors.goldDark),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ${formatRefill(remaining)}',
          style: TextStyle(
            fontSize: 12.5,
            color: widget.dark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
