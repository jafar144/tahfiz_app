import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

class MonthlyTargetTimelineEntry {
  final String sourceReportId;
  final String asatidzDisplayName;
  final MonthlyTarget target;
  final MonthlyTargetResult result;

  const MonthlyTargetTimelineEntry({
    required this.sourceReportId,
    required this.asatidzDisplayName,
    required this.target,
    required this.result,
  });

  static List<MonthlyTargetTimelineEntry> fromReports(
    List<MonthlyReport> reports,
  ) {
    final entries = <MonthlyTargetTimelineEntry>[];
    for (final source in reports) {
      final target = source.target;
      if (target == null) continue;

      MonthlyTargetEvaluation? evaluation;
      for (final report in reports) {
        final candidate = report.targetEvaluation;
        if (candidate?.evaluates(source.id, target) ?? false) {
          evaluation = candidate;
          break;
        }
      }

      entries.add(
        MonthlyTargetTimelineEntry(
          sourceReportId: source.id,
          asatidzDisplayName: source.asatidzDisplayName,
          target: target,
          result: evaluation?.result ?? MonthlyTargetResult.notAssessed,
        ),
      );
    }

    entries.sort((a, b) {
      final year = a.target.tahun.compareTo(b.target.tahun);
      if (year != 0) return year;
      return a.target.bulan.compareTo(b.target.bulan);
    });
    return entries;
  }
}

class MonthlyTargetCarousel extends StatefulWidget {
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
  State<MonthlyTargetCarousel> createState() => _MonthlyTargetCarouselState();
}

class _MonthlyTargetCarouselState extends State<MonthlyTargetCarousel> {
  late List<MonthlyTargetTimelineEntry> _entries;
  late PageController _pageController;
  late int _currentIndex;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeTimeline();
  }

  @override
  void didUpdateWidget(covariant MonthlyTargetCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextEntries = MonthlyTargetTimelineEntry.fromReports(widget.reports);
    if (_signature(nextEntries) == _signature(_entries)) return;

    _pageController.dispose();
    _entries = nextEntries;
    _currentIndex = _initialIndex(_entries);
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.94,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeTimeline() {
    _entries = MonthlyTargetTimelineEntry.fromReports(widget.reports);
    _currentIndex = _initialIndex(_entries);
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.94,
    );
  }

  int _initialIndex(List<MonthlyTargetTimelineEntry> entries) {
    if (entries.isEmpty) return 0;

    final currentIndex = entries.indexWhere(
      (entry) =>
          entry.target.bulan == _now.month && entry.target.tahun == _now.year,
    );
    if (currentIndex >= 0) return currentIndex;

    // Bila bulan berjalan belum punya target, tampilkan periode terdekat.
    var bestIndex = entries.length - 1;
    var bestDistance = 1 << 30;
    final nowValue = _now.year * 12 + _now.month;
    for (var i = 0; i < entries.length; i++) {
      final target = entries[i].target;
      final distance = (target.tahun * 12 + target.bulan - nowValue).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  String _signature(List<MonthlyTargetTimelineEntry> entries) {
    return entries
        .map(
          (entry) =>
              '${entry.sourceReportId}|${entry.target.bulan}|'
              '${entry.target.tahun}|${entry.target.minimum}|'
              '${entry.target.optimum}|${entry.result.name}',
        )
        .join(';;');
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          const Row(
            children: [
              _TargetTitleIcon(),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Bulanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF163A36),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ikhtiar terarah, dijaga sedikit demi sedikit',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B817E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
        ],
        SizedBox(
          height: 316,
          child: PageView.builder(
            key: const Key('monthly-target-page-view'),
            controller: _pageController,
            itemCount: _entries.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _MonthlyTargetCard(entry: _entries[index], now: _now),
              );
            },
          ),
        ),
        if (_entries.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavigationButton(
                key: const Key('monthly-target-previous'),
                icon: Icons.chevron_left_rounded,
                enabled: _currentIndex > 0,
                onPressed: () => _goTo(_currentIndex - 1),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 46),
                alignment: Alignment.center,
                child: Text(
                  '${_currentIndex + 1} / ${_entries.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF56716C),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _NavigationButton(
                key: const Key('monthly-target-next'),
                icon: Icons.chevron_right_rounded,
                enabled: _currentIndex < _entries.length - 1,
                onPressed: () => _goTo(_currentIndex + 1),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _entries.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class _MonthlyTargetCard extends StatelessWidget {
  final MonthlyTargetTimelineEntry entry;
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
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.asatidzDisplayName.isEmpty
                            ? 'Tetap istiqamah dalam setiap langkah.'
                            : 'Disusun bersama ${entry.asatidzDisplayName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: Color(0xFF78908C),
                        ),
                      ),
                    ),
                    if (entry.result.isAchieved) ...[
                      const SizedBox(width: 8),
                      _AchievementStamp(result: entry.result),
                    ],
                  ],
                ),
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

class _TargetTitleIcon extends StatelessWidget {
  const _TargetTitleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.flag_rounded, size: 20, color: Colors.white),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavigationButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 19),
      color: const Color(0xFF0F766E),
      disabledColor: const Color(0xFFCAD8D5),
      style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F7F5)),
    );
  }
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
