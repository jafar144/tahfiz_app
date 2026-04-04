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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHafalanSection(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildNilaiIndicator(
                        'Perkembangan',
                        report.nilaiPerkembangan,
                        Icons.trending_up_rounded,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNilaiIndicator(
                        'Akhlaq',
                        report.nilaiAkhlaq,
                        Icons.favorite_rounded,
                      )),
                    ],
                  ),
                  if (report.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildNotesSection(),
                  ],
                  const SizedBox(height: 14),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.blue.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${MonthlyReport.getNamaBulan(report.bulan)} ${report.tahun}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHafalanSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(
                'Hafalan Terakhir',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.hafalanTerakhir,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiIndicator(String label, int nilai, IconData icon) {
    final color = _getNilaiColor(nilai);
    final labelText = MonthlyReport.getNilaiLabel(nilai);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            labelText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          _buildNilaiDots(nilai, color),
        ],
      ),
    );
  }

  Widget _buildNilaiDots(int nilai, Color color) {
    return Row(
      children: List.generate(5, (index) {
        final isActive = index < nilai;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.grey.shade200,
          ),
        );
      }),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATATAN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            report.notes,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          report.asatidzName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getNilaiColor(int nilai) {
    switch (nilai) {
      case 5:
        return const Color(0xFF16A34A);
      case 4:
        return const Color(0xFF22C55E);
      case 3:
        return const Color(0xFFEAB308);
      case 2:
        return const Color(0xFFF97316);
      case 1:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}
