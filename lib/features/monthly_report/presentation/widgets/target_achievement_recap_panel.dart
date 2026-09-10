import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/target_achievement_recap.dart';

class TargetAchievementRecapPanel extends StatelessWidget {
  final TargetAchievementRecap recap;

  const TargetAchievementRecapPanel({super.key, required this.recap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekap Pencapaian Target',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Semua pembimbing · ketuk untuk melihat santri',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TargetRecapCard(
                key: const Key('target_recap_not_achieved'),
                label: 'Belum\ntercapai',
                color: Colors.red,
                entries: recap.entriesFor(MonthlyTargetResult.notAchieved),
              ),
              const SizedBox(width: 8),
              _TargetRecapCard(
                key: const Key('target_recap_minimum'),
                label: 'Target\nminimum',
                color: Colors.orange,
                entries: recap.entriesFor(MonthlyTargetResult.minimumAchieved),
              ),
              const SizedBox(width: 8),
              _TargetRecapCard(
                key: const Key('target_recap_optimum'),
                label: 'Target\noptimum',
                color: Colors.green,
                entries: recap.entriesFor(MonthlyTargetResult.optimumAchieved),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetRecapCard extends StatelessWidget {
  final String label;
  final MaterialColor color;
  final List<TargetAchievementEntry> entries;

  const _TargetRecapCard({
    super.key,
    required this.label,
    required this.color,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: entries.isEmpty ? null : () => _showDetails(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '${entries.length}',
                  style: TextStyle(
                    color: color.shade800,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color.shade800,
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                label.replaceAll('\n', ' '),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.shade50,
                      foregroundColor: color.shade800,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(entry.santriName),
                    subtitle: entry.asatidzName.trim().isEmpty
                        ? null
                        : Text('Pembimbing: ${entry.asatidzName}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
