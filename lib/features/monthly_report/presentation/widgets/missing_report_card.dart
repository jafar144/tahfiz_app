import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';

/// Kartu penanda penilaian bulan lampau yang belum diisi (tertunggak).
/// Ditampilkan dengan aksen merah dan bisa ditekan untuk mengisi susulan.
class MissingReportCard extends StatelessWidget {
  final int bulan;
  final int tahun;
  final VoidCallback onTap;

  const MissingReportCard({
    super.key,
    required this.bulan,
    required this.tahun,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bulanStr = MonthlyReport.getNamaBulan(bulan);

    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.shade300, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$bulanStr $tahun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MonthlyReportStrings.belumDinilai,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    MonthlyReportStrings.isiSekarang,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.red.shade400,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
