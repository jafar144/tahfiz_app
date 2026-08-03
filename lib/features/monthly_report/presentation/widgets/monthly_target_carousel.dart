import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

class _MonthlyTargetViewData {
  final String asatidzDisplayName;
  final MonthlyTarget target;
  final MonthlyTargetResult result;

  const _MonthlyTargetViewData({
    required this.asatidzDisplayName,
    required this.target,
    required this.result,
  });
}

/// Target yang berlaku pada bulan berjalan.
///
/// Nama kelas dipertahankan agar call site lama tidak pecah, tetapi widget ini
/// tidak lagi berisi carousel atau navigasi riwayat.
class MonthlyTargetCarousel extends StatelessWidget {
  final List<MonthlyReport> reports;
  final DateTime? now;
  final bool showTitle;

  const MonthlyTargetCarousel({
    super.key,
    required this.reports,
    this.now,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const SizedBox.shrink();

    final currentDate = now ?? DateTime.now();
    final progress = MonthlyTargetProgress.forPeriod(
      reports,
      bulan: currentDate.month,
      tahun: currentDate.year,
    );
    _MonthlyTargetViewData? currentTarget;
    if (progress != null) {
      MonthlyReport? source;
      for (final report in reports) {
        if (report.id == progress.sourceReportId) {
          source = report;
          break;
        }
      }
      currentTarget = _MonthlyTargetViewData(
        asatidzDisplayName: source?.asatidzDisplayName ?? '',
        target: progress.target,
        result: progress.result,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const Text(
            'Target Bulan Ini',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (currentTarget == null)
          const _MonthlyTargetEmptyState()
        else
          _MonthlyTargetCard(entry: currentTarget, now: currentDate),
      ],
    );
  }
}

class _MonthlyTargetEmptyState extends StatelessWidget {
  const _MonthlyTargetEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('monthly-target-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDEBE8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF134E4A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target bulan ini belum tersedia',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF163A36),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Target akan tampil setelah asatidz menyimpannya.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B817E)),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTargetCard extends StatelessWidget {
  final _MonthlyTargetViewData entry;
  final DateTime now;

  const _MonthlyTargetCard({required this.entry, required this.now});

  static const _emerald = Color(0xFF0F766E);
  static const _dark = Color(0xFF163A36);
  static const _gold = Color(0xFFC18B2B);

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus();
    final minimumReached =
        entry.result == MonthlyTargetResult.minimumAchieved ||
        entry.result == MonthlyTargetResult.optimumAchieved;
    final optimumReached = entry.result == MonthlyTargetResult.optimumAchieved;

    return Container(
      key: Key('monthly-target-${entry.target.tahun}-${entry.target.bulan}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDEBE8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF134E4A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -44,
            right: -32,
            child: _DecorativeOrb(size: 132, color: Color(0xFFE0F3EE)),
          ),
          const Positioned(
            top: 31,
            right: 34,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Color(0xFF93C5B8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MonthlyReport.getNamaBulan(
                              entry.target.bulan,
                            ).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: _emerald,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.target.tahun}',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 13),
                const Divider(height: 1, color: Color(0xFFEAF2F0)),
                const SizedBox(height: 14),
                _TargetRow(
                  icon: Icons.spa_outlined,
                  color: _emerald,
                  label: 'TARGET MINIMUM',
                  value: entry.target.minimum,
                  reached: minimumReached,
                ),
                const SizedBox(height: 13),
                _TargetRow(
                  icon: Icons.auto_awesome_rounded,
                  color: _gold,
                  label: 'TARGET OPTIMUM',
                  value: entry.target.optimum,
                  reached: optimumReached,
                ),
                if (entry.asatidzDisplayName.isNotEmpty ||
                    entry.result.isAchieved) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (entry.asatidzDisplayName.isNotEmpty)
                        Expanded(
                          child: Text(
                            entry.asatidzDisplayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.3,
                              color: Color(0xFF78908C),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (entry.result.isAchieved) ...[
                        const SizedBox(width: 8),
                        _AchievementStamp(result: entry.result),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TargetStatus _resolveStatus() {
    if (entry.result != MonthlyTargetResult.notAssessed) {
      return switch (entry.result) {
        MonthlyTargetResult.notAchieved => const _TargetStatus(
          'Belum tercapai',
          Color(0xFFB45309),
          Color(0xFFFFF7ED),
          Icons.refresh_rounded,
        ),
        MonthlyTargetResult.minimumAchieved => const _TargetStatus(
          'Minimum tercapai',
          Color(0xFF047857),
          Color(0xFFECFDF5),
          Icons.check_circle_outline_rounded,
        ),
        MonthlyTargetResult.optimumAchieved => const _TargetStatus(
          'Optimum tercapai',
          Color(0xFF0F766E),
          Color(0xFFF0FDFA),
          Icons.workspace_premium_outlined,
        ),
        MonthlyTargetResult.notAssessed => throw StateError('unreachable'),
      };
    }

    final period = DateTime(entry.target.tahun, entry.target.bulan);
    final current = DateTime(now.year, now.month);
    if (period.isBefore(current)) {
      return const _TargetStatus(
        'Belum dinilai',
        Color(0xFF6B7280),
        Color(0xFFF3F4F6),
        Icons.schedule_rounded,
      );
    }
    if (period.isAfter(current)) {
      return const _TargetStatus(
        'Akan datang',
        Color(0xFF2563EB),
        Color(0xFFEFF6FF),
        Icons.calendar_month_outlined,
      );
    }
    return const _TargetStatus(
      'Sedang berjalan',
      Color(0xFF0F766E),
      Color(0xFFF0FDFA),
      Icons.timelapse_rounded,
    );
  }
}

class _TargetRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool reached;

  const _TargetRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.55,
                        color: color,
                      ),
                    ),
                  ),
                  if (reached)
                    Icon(Icons.check_circle_rounded, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.38,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF304B47),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementStamp extends StatelessWidget {
  final MonthlyTargetResult result;

  const _AchievementStamp({required this.result});

  @override
  Widget build(BuildContext context) {
    final optimum = result == MonthlyTargetResult.optimumAchieved;
    final color = optimum ? const Color(0xFF0F766E) : const Color(0xFF047857);
    return Transform.rotate(
      angle: -0.045,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.72), width: 1.2),
        ),
        child: Text(
          optimum ? 'OPTIMUM TERCAPAI' : 'MINIMUM TERCAPAI',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.55,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _TargetStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetStatus {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const _TargetStatus(this.label, this.color, this.background, this.icon);
}

class _DecorativeOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
