import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/journey/domain/journey_level.dart';
import 'package:khoirunnasyien/features/journey/presentation/journey_colors.dart';

/// Bottom sheet detail satu tingkat perjalanan.
class LevelDetailSheet extends StatelessWidget {
  final JourneyLevel level;
  final int total;

  const LevelDetailSheet({
    super.key,
    required this.level,
    required this.total,
  });

  static void show(BuildContext context, JourneyLevel level, int total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LevelDetailSheet(level: level, total: total),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (String statusLabel, Color statusColor) = switch (level.status) {
      JourneyStatus.completed => ('Selesai', JourneyColors.sage),
      JourneyStatus.active => ('Sedang dijalani', JourneyColors.gold),
      JourneyStatus.locked => ('Belum ditempuh', JourneyColors.muted),
    };

    final message = switch (level.status) {
      JourneyStatus.completed =>
        'Alhamdulillah, tahap ini telah kamu selesaikan. Teruskan istiqomah-mu.',
      JourneyStatus.active =>
        'Inilah tahap yang sedang kamu tempuh saat ini. Semangat, semoga Allah mudahkan.',
      JourneyStatus.locked =>
        'Tahap ini akan terbuka setelah kamu menyelesaikan tahap sebelumnya.',
    };

    final badgeColors = level.isCompleted
        ? const [JourneyColors.gold, JourneyColors.goldLight]
        : level.isActive
            ? const [JourneyColors.primaryDeep, JourneyColors.primaryMid]
            : const [JourneyColors.lockedBg, JourneyColors.lockedBg];

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: JourneyColors.sand,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JourneyColors.sandDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: badgeColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColors.first.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                level.isLocked ? Icons.lock_rounded : level.icon,
                size: 34,
                color: level.isCompleted
                    ? JourneyColors.primaryDeep
                    : level.isActive
                        ? Colors.white
                        : JourneyColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              level.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: JourneyColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tingkat ${level.number} dari $total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: JourneyColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: JourneyColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang tahap ini',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: JourneyColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    level.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: JourneyColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    level.isCompleted
                        ? Icons.verified_rounded
                        : level.isActive
                            ? Icons.auto_awesome_rounded
                            : Icons.lock_clock_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: JourneyColors.charcoal.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: JourneyColors.sandDark,
                  foregroundColor: JourneyColors.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
