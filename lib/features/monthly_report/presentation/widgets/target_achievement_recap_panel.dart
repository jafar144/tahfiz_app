import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/target_achievement_recap.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_palette.dart';

class TargetAchievementRecapPanel extends StatelessWidget {
  final TargetAchievementRecap recap;
  final String periodLabel;

  const TargetAchievementRecapPanel({
    super.key,
    required this.recap,
    required this.periodLabel,
  });

  static const _groups = [
    (
      TargetRecapGroup.penalized,
      'Kena hukuman',
      MonthlyReportPalette.penalized,
    ),
    (
      TargetRecapGroup.excused,
      'Tidak capai, tanpa hukuman',
      MonthlyReportPalette.excused,
    ),
    (TargetRecapGroup.minimum, 'Capai minimum', MonthlyReportPalette.minimum),
    (TargetRecapGroup.optimum, 'Capai optimum', MonthlyReportPalette.optimum),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pencapaian target',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MonthlyReportPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recap.total == 0
                ? 'Belum ada santri yang dievaluasi'
                : '${recap.total} santri sudah dievaluasi',
            style: const TextStyle(
              fontSize: 13,
              color: MonthlyReportPalette.muted,
            ),
          ),
          const SizedBox(height: 16),
          if (recap.total == 0)
            _buildEmpty()
          else ...[
            _DistributionBar(
              segments: [
                for (final (group, _, color) in _groups)
                  (recap.countFor(group), color),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MonthlyReportPalette.line),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _groups.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        indent: 44,
                        color: MonthlyReportPalette.line,
                      ),
                    _GroupRow(
                      key: Key('target_recap_${_groups[i].$1.name}'),
                      label: _groups[i].$2,
                      color: _groups[i].$3,
                      entries: recap.entriesFor(_groups[i].$1),
                      periodLabel: periodLabel,
                      isFirst: i == 0,
                      isLast: i == _groups.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MonthlyReportPalette.line),
      ),
      child: Text(
        'Rekap $periodLabel muncul setelah pembimbing mengisi penilaian.',
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: MonthlyReportPalette.muted,
        ),
      ),
    );
  }
}

/// Bar proporsi dari merah (hukuman) ke hijau (optimum).
class _DistributionBar extends StatelessWidget {
  final List<(int, Color)> segments;

  const _DistributionBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((segment) => segment.$1 > 0).toList();
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: visible[i].$1,
                  child: ColoredBox(color: visible[i].$2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final String label;
  final Color color;
  final List<TargetAchievementEntry> entries;
  final String periodLabel;
  final bool isFirst;
  final bool isLast;

  const _GroupRow({
    super.key,
    required this.label,
    required this.color,
    required this.entries,
    required this.periodLabel,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final empty = entries.isEmpty;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return Semantics(
      button: !empty,
      label: '$label, ${entries.length} santri',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: radius,
        onTap: empty ? null : () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MonthlyReportPalette.ink,
                  ),
                ),
              ),
              Text(
                '${entries.length}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: empty
                      ? MonthlyReportPalette.muted.withValues(alpha: 0.6)
                      : MonthlyReportPalette.ink,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: empty ? Colors.transparent : MonthlyReportPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: MonthlyReportPalette.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entries.length} santri pada $periodLabel',
                            style: const TextStyle(
                              fontSize: 13,
                              color: MonthlyReportPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup daftar santri',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: MonthlyReportPalette.line),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 64,
                    color: MonthlyReportPalette.line,
                  ),
                  itemBuilder: (context, index) =>
                      _EntryTile(entry: entries[index], number: index + 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TargetAchievementEntry entry;
  final int number;

  const _EntryTile({required this.entry, required this.number});

  @override
  Widget build(BuildContext context) {
    final teacher = entry.asatidzName.trim();
    final excuse = entry.penaltyExcuse.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$number.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                color: MonthlyReportPalette.muted,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.santriName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MonthlyReportPalette.ink,
                  ),
                ),
                if (teacher.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Pembimbing: $teacher',
                    style: const TextStyle(
                      fontSize: 13,
                      color: MonthlyReportPalette.muted,
                    ),
                  ),
                ],
                if (excuse.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: MonthlyReportPalette.excused,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      excuse,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: MonthlyReportPalette.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
