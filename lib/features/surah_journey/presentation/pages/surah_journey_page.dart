import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/night_loading_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_state.dart';

/// Peta Petualangan Surah bergaya game: jalur berkelok bernuansa malam islami
/// (bintang + bulan sabit), node level dari bawah ke atas. Level terkunci
/// sampai level sebelumnya selesai; yang selesai diberi centang hijau.
class SurahJourneyPage extends StatelessWidget {
  const SurahJourneyPage({super.key});

  // Palet nuansa malam (langit gelap kehijauan → bukit).
  static const _skyTop = Color(0xFF0B2540);
  static const _skyBottom = Color(0xFF123B33);
  static const _hillDark = Color(0xFF0E4429);
  static const _hillLight = Color(0xFF166534);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_skyTop, _skyBottom],
          ),
        ),
        child: const SafeArea(bottom: false, child: SurahJourneyView()),
      ),
    );
  }
}

/// Isi peta Petualangan Surah (header + peta) TANPA Scaffold/gradien sendiri —
/// dipakai halaman mandiri di atas, dan ditanam sebagai tab di Tahfiz Arena
/// ([showBack] false karena Arena punya top bar sendiri).
class SurahJourneyView extends StatelessWidget {
  final bool showBack;

  const SurahJourneyView({super.key, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurahJourneyCubit, SurahJourneyState>(
      buildWhen: (p, c) => p.status != c.status,
      builder: (context, state) {
        final isLoading = state.status == JourneyStatus.loading;
        // Halaman loading dedicated ditukar ke konten (header + peta/error)
        // dengan fade lembut. Hindari slide horizontal di sini agar tidak
        // terasa seperti navigasi kedua setelah route/back animation selesai.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: isLoading
              ? NightLoadingPage(
                  key: const ValueKey('journey-loading'),
                  title: 'Menyiapkan Petualanganmu…',
                  subtitle: 'Memuat progres, XP, dan energimu',
                  showBack: showBack,
                  onBack: () => context.pop(),
                )
              : _JourneyContent(
                  key: const ValueKey('journey-content'),
                  showBack: showBack,
                ),
        );
      },
    );
  }
}

/// Konten setelah data siap: header (juz/XP/energi) + peta atau layar error.
class _JourneyContent extends StatelessWidget {
  final bool showBack;

  const _JourneyContent({super.key, required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(showBack: showBack),
        Expanded(
          child: BlocBuilder<SurahJourneyCubit, SurahJourneyState>(
            builder: (context, state) {
              return switch (state.status) {
                JourneyStatus.error => _ErrorView(
                  message: state.errorMessage ?? 'Terjadi kesalahan.',
                  onRetry: () => context.read<SurahJourneyCubit>().load(),
                ),
                JourneyStatus.ready => _JourneyMap(state: state),
                JourneyStatus.loading => const SizedBox.shrink(),
              };
            },
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────── Header ──

/// Tombol bulat "kembali" bergaya journey — dipakai header & halaman loading.
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}

/// Top bar peta ala Duolingo: kiri pilihan Juz (dropdown; juz 29 masih
/// terkunci), kanan lencana XP & energi — ikon ber-border putih + angka
/// (bukan chip). Ketuk XP/energi → halaman detail (naik dari bawah).
class _Header extends StatelessWidget {
  final bool showBack;

  const _Header({this.showBack = true});

  void _openStats(BuildContext context, SurahJourneyState state, String focus) {
    context.pushNamed(
      RouteNames.arenaStats,
      extra: <String, dynamic>{
        'xp': state.xp,
        'energy': state.energy,
        'focus': focus,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBack ? 12 : 16, 8, 16, 8),
      child: BlocBuilder<SurahJourneyCubit, SurahJourneyState>(
        builder: (context, state) {
          final energy = state.energy;
          return Row(
            children: [
              if (showBack) ...[
                _BackButton(onTap: () => context.pop()),
                const SizedBox(width: 10),
              ],
              _JuzDropdown(selected: state.selectedJuz),
              const Spacer(),
              if (state.status == JourneyStatus.ready) ...[
                // ── XP: bintang biru + angka ──
                _HeaderStat(
                  icon: Icons.star_rounded,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4FC3F7), QuizColors.xpBlue],
                  ),
                  value: '${state.xp}',
                  valueColor: QuizColors.xpBlue,
                  onTap: () => _openStats(context, state, 'xp'),
                ),
                const SizedBox(width: 12),
                // ── Energi: hilal emas + angka ──
                if (energy != null)
                  _EnergyHeaderStat(
                    energy: energy,
                    onTap: () => _openStats(context, state, 'energy'),
                    onRefillReady: () =>
                        context.read<SurahJourneyCubit>().refreshEnergy(),
                  )
                else if (state.energyLoading)
                  const EnergyBadgeSkeleton(),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Satu lencana stat ala Duolingo: ikon squircle ber-border putih + angka.
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;

  const _HeaderStat({
    required this.icon,
    required this.gradient,
    required this.value,
    required this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: 15.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lencana energi header: gaya [_HeaderStat] + timer yang memuat ulang energi
/// saat waktu pengisian tiba (perilaku lama EnergyBadge dipertahankan).
class _EnergyHeaderStat extends StatefulWidget {
  final QuizEnergy energy;
  final VoidCallback? onTap;
  final VoidCallback? onRefillReady;

  const _EnergyHeaderStat({
    required this.energy,
    this.onTap,
    this.onRefillReady,
  });

  @override
  State<_EnergyHeaderStat> createState() => _EnergyHeaderStatState();
}

class _EnergyHeaderStatState extends State<_EnergyHeaderStat> {
  Timer? _timer;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _ensureTimer();
  }

  @override
  void didUpdateWidget(_EnergyHeaderStat oldWidget) {
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
      final t = widget.energy.nextRefillAt;
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

  @override
  Widget build(BuildContext context) {
    final empty = !widget.energy.canPlay;
    return _HeaderStat(
      icon: kEnergyIcon,
      gradient: empty
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE57373), Color(0xFFC62828)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [QuizColors.gold, QuizColors.goldDark],
            ),
      value: '${widget.energy.current}',
      valueColor: empty ? QuizColors.missingBright : QuizColors.gold,
      onTap: widget.onTap,
    );
  }
}

/// Pil dropdown pemilih juz — juz yang belum tersedia tampil terkunci.
class _JuzDropdown extends StatelessWidget {
  final int selected;

  const _JuzDropdown({required this.selected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      color: const Color(0xFF14324A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 42),
      itemBuilder: (context) => [
        for (final opt in SurahJourneyState.juzOptions)
          PopupMenuItem<int>(
            value: opt.juz,
            enabled: opt.available,
            child: Row(
              children: [
                Icon(
                  opt.available
                      ? (opt.juz == selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined)
                      : Icons.lock_rounded,
                  size: 18,
                  color: opt.available
                      ? (opt.juz == selected ? QuizColors.gold : Colors.white54)
                      : Colors.white30,
                ),
                const SizedBox(width: 10),
                Text(
                  'Juz ${opt.juz}',
                  style: TextStyle(
                    color: opt.available ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                if (!opt.available) ...[
                  const Spacer(),
                  const Text(
                    'Segera',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
      ],
      // Sementara hanya juz 30 yang bisa dipilih — tak ada aksi lain.
      onSelected: (_) {},
      // Gaya sama dengan lencana XP/energi: ikon squircle ber-border putih +
      // teks; ketuk tetap membuka dropdown juz.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF34D399), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Juz $selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── Peta ──

class _JourneyMap extends StatefulWidget {
  final SurahJourneyState state;

  const _JourneyMap({required this.state});

  @override
  State<_JourneyMap> createState() => _JourneyMapState();
}

class _JourneyMapState extends State<_JourneyMap> {
  static const double _spacing = 168; // jarak vertikal antar node
  static const double _bottomPad = 150; // ruang bukit di bawah node pertama
  static const double _topPad = 110;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Posisi horizontal node ke-[i] (0 = level 1 paling bawah) — pola zigzag.
  double _xFrac(int i, int count) {
    if (i == 0 || i == count - 1) return 0.5; // awal & "segera hadir" di tengah
    return i.isOdd ? 0.27 : 0.73;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.state.nodes;
    final count = nodes.length + 1; // + node "Segera Hadir"
    final mapHeight = _topPad + _bottomPad + _spacing * (count - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Titik pusat tiap node, dihitung dari bawah.
        final centers = List<Offset>.generate(count, (i) {
          return Offset(
            width * _xFrac(i, count),
            mapHeight - _bottomPad - i * _spacing,
          );
        });

        return SingleChildScrollView(
          controller: _scroll,
          reverse: true, // mulai dari bawah (level 1)
          child: SizedBox(
            width: width,
            height: mapHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bintang + bulan sabit + bukit.
                Positioned.fill(child: CustomPaint(painter: _SkyPainter())),
                // Jalur titik-titik antar node.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter(
                      centers: centers,
                      // Segmen i (node i → i+1) emas bila level i selesai.
                      goldSegments: [
                        for (var i = 0; i < count - 1; i++)
                          i < nodes.length && nodes[i].completed,
                      ],
                    ),
                  ),
                ),
                // Node level.
                for (var i = 0; i < nodes.length; i++)
                  _positionNode(
                    center: centers[i],
                    child: _LevelNode(
                      node: nodes[i],
                      onTap: () => _onNodeTap(context, i),
                    ),
                  ),
                // Node "Segera Hadir".
                _positionNode(
                  center: centers[count - 1],
                  child: const _ComingSoonNode(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bungkus node dalam [Positioned] yang berpusat di [center].
  Widget _positionNode({required Offset center, required Widget child}) {
    const boxWidth = 140.0;
    return Positioned(
      left: center.dx - boxWidth / 2,
      top: center.dy - 44,
      width: boxWidth,
      child: child,
    );
  }

  Future<void> _onNodeTap(BuildContext context, int index) async {
    final node = widget.state.nodes[index];
    if (!node.unlocked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Selesaikan ${widget.state.nodes[index - 1].lesson.nameLatin} '
              'dulu untuk membuka level ini, ya!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final cubit = context.read<SurahJourneyCubit>();
    await context.pushNamed(RouteNames.surahLesson, extra: node.lesson);
    // Muat ulang progres saat kembali dari sesi belajar/ujian — senyap
    // (tanpa halaman loading), peta cukup ter-update di tempat.
    cubit.refresh();
  }
}

// ──────────────────────────────────────────────────────────────────── Node ──

class _LevelNode extends StatelessWidget {
  final JourneyLevelNode node;
  final VoidCallback onTap;

  const _LevelNode({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final completed = node.completed;
    final unlocked = node.unlocked;

    final Widget circle;
    if (completed) {
      circle = _NodeCircle(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ),
        ringColor: QuizColors.gold,
        shadowColor: const Color(0xFF10B981),
        icon: Icons.check_rounded,
      );
    } else if (unlocked) {
      circle = _PulsingHalo(
        child: _NodeCircle(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [QuizColors.gold, QuizColors.goldDark],
          ),
          ringColor: Colors.white,
          shadowColor: QuizColors.gold,
          icon: Icons.menu_book_rounded,
        ),
      );
    } else {
      circle = _NodeCircle(
        color: const Color(0xFF1E3A5F).withValues(alpha: 0.9),
        ringColor: Colors.white24,
        icon: Icons.lock_rounded,
        iconColor: Colors.white38,
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: 7),
        // Nama surah.
        Text(
          node.lesson.nameLatin,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: unlocked ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 3),
        // Status: nilai terbaik / ajakan mulai / terkunci.
        if (completed)
          _chip('Nilai ${node.progress.examBestScore}', QuizColors.gold)
        else if (unlocked)
          _chip('MULAI', Colors.white)
        else
          Text(
            'Level ${node.lesson.level}',
            style: const TextStyle(color: Colors.white24, fontSize: 10.5),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Hanya node AKTIF (terbuka, belum selesai) yang mengambang; seluruh isi
      // node (lingkaran + label) ikut bergerak bersama sebagai satu kesatuan.
      child: (unlocked && !completed) ? _FloatBob(child: content) : content,
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Lingkaran dasar sebuah node.
class _NodeCircle extends StatelessWidget {
  final Gradient? gradient;
  final Color? color;
  final Color ringColor;
  final Color? shadowColor;
  final IconData icon;
  final Color iconColor;

  const _NodeCircle({
    this.gradient,
    this.color,
    required this.ringColor,
    this.shadowColor,
    required this.icon,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        color: color,
        border: Border.all(color: ringColor, width: 3),
        boxShadow: [
          if (shadowColor != null)
            BoxShadow(
              color: shadowColor!.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 32),
    );
  }
}

/// Halo berdenyut di belakang node yang sedang bisa dimainkan.
class _PulsingHalo extends StatefulWidget {
  final Widget child;

  const _PulsingHalo({required this.child});

  @override
  State<_PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<_PulsingHalo>
    with SingleTickerProviderStateMixin {
  // reverse: true → nilai naik 0→1 lalu TURUN 1→0 dengan mulus (bawah-atas),
  // bukan meloncat balik ke 0 (yang tampak "patah").
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  // Kurva easeInOut agar pergerakan naik-turunnya melambat di ujung (halus).
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        // Footprint dikunci 68x68 (ukuran node); halo yang membesar dibiarkan
        // MELUBER keluar lewat OverflowBox agar TIDAK menambah tinggi kolom —
        // sehingga label surah di bawahnya tak ikut tergeser saat halo bernapas.
        return SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Halo emas yang "bernapas" mengikuti denyut (membesar-mengecil).
              Center(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Container(
                    width: 68 + 22 * t,
                    height: 68 + 22 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: QuizColors.gold.withValues(
                          alpha: 0.15 + 0.5 * (1 - t),
                        ),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Membuat seluruh node "mengambang" naik-turun lembut sebagai SATU kesatuan —
/// lingkaran & label bergerak bersama dengan jarak yang sama (bukan cuma halo).
class _FloatBob extends StatefulWidget {
  final Widget child;

  const _FloatBob({required this.child});

  @override
  State<_FloatBob> createState() => _FloatBobState();
}

class _FloatBobState extends State<_FloatBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, -5 * _t.value), child: child),
      child: widget.child,
    );
  }
}

/// Node "level berikutnya segera hadir".
class _ComingSoonNode extends StatelessWidget {
  const _ComingSoonNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Colors.white38,
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Segera Hadir',
          style: TextStyle(color: Colors.white38, fontSize: 11.5),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── Painters ──

/// Latar peta: bintang berkelip statis, bulan sabit, bukit di kaki peta.
class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7); // seed tetap → pola bintang stabil
    final star = Paint()..color = Colors.white.withValues(alpha: 0.7);

    // Bintang kecil tersebar (lebih rapat di bagian atas).
    final starCount = (size.height / 14).round();
    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.6 + rng.nextDouble() * 1.3;
      star.color = Colors.white.withValues(
        alpha: 0.25 + rng.nextDouble() * 0.5,
      );
      canvas.drawCircle(Offset(x, y), r, star);
    }

    // Beberapa bintang berbentuk kilau (4 sisi).
    final sparkle = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < max(3, starCount ~/ 12); i++) {
      final c = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height * 0.8,
      );
      final s = 3.5 + rng.nextDouble() * 3;
      final path = Path()
        ..moveTo(c.dx, c.dy - s)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s);
      canvas.drawPath(path, sparkle);
    }

    // Bulan sabit di kanan atas.
    final moonCenter = Offset(size.width * 0.82, 64);
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moonCenter, radius: 26)),
      Path()..addOval(
        Rect.fromCircle(center: moonCenter.translate(11, -7), radius: 23),
      ),
    );
    canvas.drawPath(
      moon,
      Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 0.9),
    );

    // Bukit dua lapis di kaki peta.
    final hillBack = Paint()..color = SurahJourneyPage._hillDark;
    final hillFront = Paint()..color = SurahJourneyPage._hillLight;
    final h = size.height;
    final backPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 105)
      ..quadraticBezierTo(size.width * 0.3, h - 175, size.width * 0.62, h - 98)
      ..quadraticBezierTo(size.width * 0.85, h - 45, size.width, h - 90)
      ..lineTo(size.width, h)
      ..close();
    canvas.drawPath(backPath, hillBack);
    final frontPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 55)
      ..quadraticBezierTo(size.width * 0.42, h - 120, size.width * 0.78, h - 40)
      ..quadraticBezierTo(size.width * 0.92, h - 12, size.width, h - 28)
      ..lineTo(size.width, h)
      ..close();
    canvas.drawPath(frontPath, hillFront);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => false;
}

/// Jalur titik-titik berkelok yang menghubungkan node level.
class _TrailPainter extends CustomPainter {
  final List<Offset> centers;

  /// Per segmen (node i → i+1): true = sudah ditempuh (emas).
  final List<bool> goldSegments;

  _TrailPainter({required this.centers, required this.goldSegments});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      // Kurva S halus antar dua node (kontrol vertikal di tengah).
      final midY = (a.dy + b.dy) / 2;
      final seg = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);

      final gold = i < goldSegments.length && goldSegments[i];
      final dot = Paint()
        ..color = gold
            ? QuizColors.gold.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.30);

      // Taburkan titik sepanjang segmen; lewati area dekat pusat node agar
      // tidak menembus lingkaran.
      for (final metric in seg.computeMetrics()) {
        const step = 21.0;
        for (var d = step; d < metric.length - step / 2; d += step) {
          final pos = metric.getTangentForOffset(d)?.position;
          if (pos == null) continue;
          if ((pos - a).distance < 48 || (pos - b).distance < 48) continue;
          canvas.drawCircle(pos, gold ? 4.0 : 3.4, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      oldDelegate.centers != centers ||
      oldDelegate.goldSegments != goldSegments;
}

// ──────────────────────────────────────────────────────────────────── Error ──

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
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            QuizButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              color: QuizColors.nightButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
