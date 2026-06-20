import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';
import 'package:khoirunnasyien/features/journey/presentation/journey_colors.dart';
import 'package:khoirunnasyien/features/journey/presentation/widgets/islamic_pattern_painter.dart';
import 'package:khoirunnasyien/features/journey/presentation/widgets/journey_timeline_tile.dart';
import 'package:khoirunnasyien/features/journey/presentation/widgets/level_detail_sheet.dart';

/// Halaman peta perjalanan tahfiz santri (seluruh tingkat).
///
/// Tingkat ditampilkan dari bawah ke atas: tingkat 1 di paling bawah, tingkat
/// tertinggi di paling atas. Saat dibuka, posisi awal berada di bawah lalu
/// santri scroll ke atas untuk melihat tingkat-tingkat berikutnya.
class JourneyPage extends StatefulWidget {
  final String? currentKelas;

  const JourneyPage({super.key, required this.currentKelas});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mulai dari posisi paling bawah (tingkat 1).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = JourneyBuilder.build(widget.currentKelas);
    // Urutan tampil dibalik: tingkat tertinggi di atas, tingkat 1 di bawah.
    final levels = info.levels.reversed.toList();

    return Scaffold(
      backgroundColor: JourneyColors.sand,
      body: Column(
        children: [
          _Banner(info: info),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 14),
                  child: Text(
                    'PERJALANAN BELAJARMU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: JourneyColors.muted,
                    ),
                  ),
                ),
                for (var i = 0; i < levels.length; i++)
                  JourneyTimelineTile(
                    level: levels[i],
                    total: info.total,
                    isLast: i == levels.length - 1,
                    // Garis ke tile di bawahnya (tingkat lebih rendah) berwarna
                    // emas bila tingkat tersebut sudah diselesaikan.
                    connectorDone:
                        i < levels.length - 1 && levels[i + 1].isCompleted,
                    onTap: () =>
                        LevelDetailSheet.show(context, levels[i], info.total),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final JourneyInfo info;
  const _Banner({required this.info});

  @override
  Widget build(BuildContext context) {
    final current = info.current;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [JourneyColors.primaryDeep, JourneyColors.primaryMid],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      JourneyColors.gold.withValues(alpha: 0.22),
                      JourneyColors.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Perjalanan Tahfiz',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.mosque_rounded,
                            color: JourneyColors.goldLight, size: 22),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: current == null
                          ? Text(
                              'Kelas belum diatur',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        JourneyColors.gold,
                                        JourneyColors.goldLight
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: JourneyColors.gold
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(current.icon,
                                      color: JourneyColors.primaryDeep, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tingkat ${current.number} dari ${info.total}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: JourneyColors.goldLight
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        current.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
