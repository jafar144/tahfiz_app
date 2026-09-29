import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/target_achievement_recap.dart';

class TargetAchievementRecapPanel extends StatelessWidget {
  final TargetAchievementRecap recap;
  final String periodLabel;

  const TargetAchievementRecapPanel({
    super.key,
    required this.recap,
    required this.periodLabel,
  });

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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua pembimbing · putra & putri',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (recap.total == 0)
            _buildEmpty()
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    '${recap.total}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'santri telah dievaluasi targetnya',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ketuk kategori untuk melihat daftar santri.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            _TargetRecapCard(
              key: const Key('target_recap_not_achieved'),
              label: 'Belum tercapai',
              icon: Icons.flag_outlined,
              color: const Color(0xFFD64550),
              entries: recap.entriesFor(MonthlyTargetResult.notAchieved),
              periodLabel: periodLabel,
            ),
            const SizedBox(height: 10),
            _TargetRecapCard(
              key: const Key('target_recap_minimum'),
              label: 'Target minimum',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFFAD710D),
              entries: recap.entriesFor(MonthlyTargetResult.minimumAchieved),
              periodLabel: periodLabel,
            ),
            const SizedBox(height: 10),
            _TargetRecapCard(
              key: const Key('target_recap_optimum'),
              label: 'Target optimum',
              icon: Icons.verified_outlined,
              color: const Color(0xFF2E7D5B),
              entries: recap.entriesFor(MonthlyTargetResult.optimumAchieved),
              periodLabel: periodLabel,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rekap hanya mencakup target yang sudah dievaluasi. '
              'Santri yang belum dinilai tidak dihitung sebagai belum tercapai.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Belum ada evaluasi target',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rekap $periodLabel akan muncul setelah pembimbing '
            'mengisi evaluasi pencapaian target santri.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetRecapCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<TargetAchievementEntry> entries;
  final String periodLabel;

  const _TargetRecapCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.entries,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entries.isEmpty ? null : () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: '${entries.length} santri',
                excludeSemantics: true,
                child: Text(
                  '${entries.length}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: entries.isEmpty
                    ? Colors.transparent
                    : AppColors.textSecondary,
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$periodLabel · ${entries.length} santri',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.09),
                        foregroundColor: color,
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
      ),
    );
  }
}
