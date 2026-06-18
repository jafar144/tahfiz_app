import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';
import 'package:khoirunnasyien/features/journey/presentation/journey_colors.dart';
import 'package:khoirunnasyien/features/journey/presentation/widgets/islamic_pattern_painter.dart';

/// Kartu ringkas perjalanan tahfiz di bagian atas beranda santri.
class JourneySummaryCard extends StatelessWidget {
  final JourneyInfo info;
  final VoidCallback onTap;

  const JourneySummaryCard({
    super.key,
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = info.current;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [JourneyColors.primaryDeep, JourneyColors.primaryMid],
            ),
            boxShadow: [
              BoxShadow(
                color: JourneyColors.primaryDeep.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Pola islami halus di latar.
                Positioned.fill(
                  child: CustomPaint(
                    painter: IslamicPatternPainter(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Aksen cahaya emas di pojok.
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          JourneyColors.gold.withValues(alpha: 0.25),
                          JourneyColors.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.nights_stay_rounded,
                              size: 15, color: JourneyColors.goldLight),
                          const SizedBox(width: 6),
                          Text(
                            'PERJALANAN TAHFIZ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: JourneyColors.goldLight.withValues(alpha: 0.9),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tingkat ${current!.number}/${info.total}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _CurrentBadge(icon: current.icon),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kelas Saat Ini',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.65),
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
                      const SizedBox(height: 18),
                      _ProgressTrack(info: info),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lihat perjalanan lengkap',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: JourneyColors.goldLight.withValues(alpha: 0.95),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: JourneyColors.goldLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  final IconData icon;
  const _CurrentBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [JourneyColors.gold, JourneyColors.goldLight],
        ),
        boxShadow: [
          BoxShadow(
            color: JourneyColors.gold.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: JourneyColors.primaryDeep, size: 26),
    );
  }
}

/// Indikator ruas perjalanan (tanpa angka persentase) — satu ruas per tingkat.
class _ProgressTrack extends StatelessWidget {
  final JourneyInfo info;
  const _ProgressTrack({required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(info.total, (i) {
        final Color color;
        if (i < info.currentIndex) {
          color = JourneyColors.gold;
        } else if (i == info.currentIndex) {
          color = JourneyColors.goldLight;
        } else {
          color = Colors.white.withValues(alpha: 0.18);
        }
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i == info.total - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
