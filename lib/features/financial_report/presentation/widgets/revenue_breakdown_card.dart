import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/utils/format_utils.dart';
import 'package:khoirunnasyien/features/financial_report/domain/entities/financial_report_data.dart';

/// Palet warna untuk tiap kelompok pendapatan (urut sesuai besar pendapatan).
const _palette = [
  Color(0xFF1E88E5), // biru
  Color(0xFFFD5D6F), // merah muda
  Color(0xFF0CAF60), // hijau
  Color(0xFFFFA000), // amber
  Color(0xFF8E5BE8), // ungu
  Color(0xFF26C6DA), // cyan
  Color(0xFFFF7043), // oranye
  Color(0xFF78909C), // abu kebiruan
];

Color _colorFor(int index) => _palette[index % _palette.length];

/// Kartu "Sumber Pendapatan": donut chart + legenda rincian per kelompok.
class RevenueBreakdownCard extends StatelessWidget {
  final FinancialReportData data;

  const RevenueBreakdownCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final groups = data.groups;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sumber Pendapatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pembagian pemasukan per kelompok santri',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty || data.totalRevenue == 0)
            _buildEmpty()
          else ...[
            Center(child: _buildDonut()),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline_rounded,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Belum ada pemasukan bulan ini',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDonut() {
    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 56,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < data.groups.length; i++)
                  PieChartSectionData(
                    value: data.groups[i].revenue.toDouble(),
                    color: _colorFor(i),
                    radius: 22,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FormatUtils.formatCompactRupiah(data.totalRevenue),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Total',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final total = data.totalRevenue;
    return Column(
      children: [
        for (var i = 0; i < data.groups.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colorFor(i),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.groups[i].label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${data.groups[i].paymentCount} pembayaran',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FormatUtils.formatRupiah(data.groups[i].revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      total == 0
                          ? '0%'
                          : '${(data.groups[i].revenue / total * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
