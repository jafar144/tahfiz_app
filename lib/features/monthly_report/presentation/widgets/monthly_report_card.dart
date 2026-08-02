import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';

class MonthlyReportCard extends StatelessWidget {
  final MonthlyReport report;
  final MonthlyTargetProgress? periodTarget;
  final VoidCallback? onTap;

  const MonthlyReportCard({
    super.key,
    required this.report,
    this.periodTarget,
    this.onTap,
  });

  // Palet warna mengikuti desain referensi.
  static const _ink = Color(0xFF111827);
  static const _subtle = Color(0xFF6B7280);
  static const _muted = Color(0xFF9CA3AF);
  static const _border = Color(0xFFF3F4F6);
  static const _teal = Color(0xFF0D9488);
  static const _softBg = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final hasNotes = report.notes.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bulan
            Text(
              '${MonthlyReport.getNamaBulan(report.bulan)} ${report.tahun}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            // Hafalan terakhir
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 14, color: _teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    report.hafalanTerakhir,
                    style: const TextStyle(fontSize: 14, color: _subtle),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Penilaian
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildNilaiColumn(
                    MonthlyReportStrings.perkembangan,
                    report.nilaiPerkembangan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNilaiColumn(
                    MonthlyReportStrings.akhlaq,
                    report.nilaiAkhlaq,
                  ),
                ),
              ],
            ),
            if (periodTarget != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 14),
              _TargetProgressContent(progress: periodTarget!),
            ],
            if (hasNotes) ...[
              const SizedBox(height: 14),
              _buildNotesButton(context),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 12),
            // Penilai
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: _muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    report.asatidzDisplayName,
                    style: const TextStyle(fontSize: 12, color: _subtle),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNilaiColumn(String label, int nilai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _muted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatusChip(nilai),
      ],
    );
  }

  Widget _buildStatusChip(int nilai) {
    if (nilai < 1 || nilai > 5) {
      return const Text(
        MonthlyReportStrings.nilaiKosong,
        style: TextStyle(fontSize: 13, color: _muted),
      );
    }
    final style = _statusStyle(nilai);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.13)),
      ),
      child: Text(
        MonthlyReport.getNilaiLabel(nilai),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style.color,
        ),
      ),
    );
  }

  Widget _buildNotesButton(BuildContext context) {
    return InkWell(
      onTap: () => _showNotesSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _softBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 15, color: _muted),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                MonthlyReportStrings.adaCatatan,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _subtle,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
          ],
        ),
      ),
    );
  }

  void _showNotesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotesBottomSheet(report: report),
    );
  }

  _StatusStyle _statusStyle(int nilai) {
    switch (nilai) {
      case 5:
        return const _StatusStyle(Color(0xFF0D9488), Color(0xFFF0FDFA));
      case 4:
        return const _StatusStyle(Color(0xFF10B981), Color(0xFFECFDF5));
      case 3:
        return const _StatusStyle(Color(0xFFF59E0B), Color(0xFFFFFBEB));
      case 2:
        return const _StatusStyle(Color(0xFFF97316), Color(0xFFFFF7ED));
      case 1:
        return const _StatusStyle(Color(0xFFEF4444), Color(0xFFFEF2F2));
      default:
        return const _StatusStyle(Color(0xFF9CA3AF), Color(0xFFF3F4F6));
    }
  }
}

/// Ringkasan target bulan berjalan yang ditempatkan di bawah header santri.
class CurrentMonthlyTargetCard extends StatelessWidget {
  final MonthlyTargetProgress progress;

  const CurrentMonthlyTargetCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('current-month-target-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7EAE6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _TargetProgressContent(progress: progress),
    );
  }
}

class _TargetProgressContent extends StatelessWidget {
  final MonthlyTargetProgress progress;

  const _TargetProgressContent({required this.progress});

  static const _ink = Color(0xFF1F2937);
  static const _subtle = Color(0xFF6B7280);
  static const _teal = Color(0xFF0F766E);
  static const _gold = Color(0xFFB7791F);

  @override
  Widget build(BuildContext context) {
    final result = progress.result;
    final minimumReached =
        result == MonthlyTargetResult.minimumAchieved ||
        result == MonthlyTargetResult.optimumAchieved;
    final optimumReached = result == MonthlyTargetResult.optimumAchieved;

    return Column(
      key: const Key('monthly-report-target-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.flag_outlined, size: 17, color: _teal),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Target ${MonthlyReport.getNamaBulan(progress.target.bulan)} '
                '${progress.target.tahun}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TargetResultBadge(result: result),
          ],
        ),
        const SizedBox(height: 12),
        _TargetValueRow(
          key: const Key('monthly-target-minimum'),
          label: MonthlyReportStrings.targetMinimum,
          value: progress.target.minimum,
          color: _teal,
          reached: minimumReached,
        ),
        const SizedBox(height: 10),
        _TargetValueRow(
          key: const Key('monthly-target-optimum'),
          label: MonthlyReportStrings.targetOptimum,
          value: progress.target.optimum,
          color: _gold,
          reached: optimumReached,
        ),
      ],
    );
  }
}

class _TargetValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool reached;

  const _TargetValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            reached ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: reached ? color : const Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.45,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: _TargetProgressContent._subtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetResultBadge extends StatelessWidget {
  final MonthlyTargetResult result;

  const _TargetResultBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final style = switch (result) {
      MonthlyTargetResult.notAssessed => const _TargetResultStyle(
        label: 'Belum dinilai',
        color: Color(0xFF6B7280),
        background: Color(0xFFF3F4F6),
      ),
      MonthlyTargetResult.notAchieved => const _TargetResultStyle(
        label: 'Belum tercapai',
        color: Color(0xFFB91C1C),
        background: Color(0xFFFEF2F2),
      ),
      MonthlyTargetResult.minimumAchieved => const _TargetResultStyle(
        label: 'Minimum tercapai',
        color: Color(0xFF047857),
        background: Color(0xFFECFDF5),
      ),
      MonthlyTargetResult.optimumAchieved => const _TargetResultStyle(
        label: 'Optimum tercapai',
        color: Color(0xFF0F766E),
        background: Color(0xFFF0FDFA),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: style.color,
        ),
      ),
    );
  }
}

class _TargetResultStyle {
  final String label;
  final Color color;
  final Color background;

  const _TargetResultStyle({
    required this.label,
    required this.color,
    required this.background,
  });
}

class _StatusStyle {
  final Color color;
  final Color bg;
  const _StatusStyle(this.color, this.bg);
}

class _NotesBottomSheet extends StatelessWidget {
  final MonthlyReport report;

  const _NotesBottomSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        MonthlyReportStrings.catatanUstadz,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${MonthlyReport.getNamaBulan(report.bulan)} ${report.tahun}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  report.notes,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    MonthlyReportStrings.dinilaiOleh(report.asatidzDisplayName),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
