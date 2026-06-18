import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

class MonthlyReportCard extends StatelessWidget {
  final MonthlyReport report;
  final VoidCallback? onTap;

  const MonthlyReportCard({
    super.key,
    required this.report,
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
                      'Perkembangan', report.nilaiPerkembangan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNilaiColumn('Akhlaq', report.nilaiAkhlaq),
                ),
              ],
            ),
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
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: _muted),
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
      return const Text('—', style: TextStyle(fontSize: 13, color: _muted));
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
                'Ada catatan dari ustadz',
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
                  child: const Icon(Icons.sticky_note_2_outlined,
                      size: 18, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Ustadz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${MonthlyReport.getNamaBulan(report.bulan)} ${report.tahun}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
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
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dinilai oleh ${report.asatidzDisplayName}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
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
