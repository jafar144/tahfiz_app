import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/pembimbing_assessment.dart';

/// Kartu ringkasan status penilaian satu pembimbing untuk sisi admin.
///
/// Menampilkan nama pembimbing, badge status bertingkat, jumlah santri
/// yang belum dinilai, dan tombol pengingat WhatsApp (hanya bila masih
/// ada yang belum dinilai).
class PembimbingAssessmentCard extends StatelessWidget {
  final PembimbingAssessment data;
  final VoidCallback onRemind;

  const PembimbingAssessmentCard({
    super.key,
    required this.data,
    required this.onRemind,
  });

  static const _completeColor = Color(0xFF2E7D5B);
  static const _almostColor = Color(0xFFE8A33D);
  static const _pendingColor = Color(0xFFD64550);

  /// Menentukan tingkatan status berdasarkan persentase belum dinilai.
  _AssessmentTier get _tier {
    if (data.isComplete) {
      return const _AssessmentTier('Alhamdulillah', _completeColor);
    }
    if (data.unassessedPercent <= 50) {
      return const _AssessmentTier('Hampir Selesai', _almostColor);
    }
    return const _AssessmentTier('Yahdik Alfa Marrah', _pendingColor);
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = data.isComplete;
    final tier = _tier;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            spreadRadius: 1,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.asatidzName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pembimbing',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(tier: tier),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tier.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComplete
                      ? 'Semua santri sudah dinilai'
                      : '${data.unassessedCount} dari ${data.totalSantri} santri belum dinilai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tier.color,
                  ),
                ),
              ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRemind,
                icon: const Icon(Icons.chat, size: 15),
                label: const Text('Ingatkan via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25A05B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssessmentTier {
  final String label;
  final Color color;
  const _AssessmentTier(this.label, this.color);
}

class _StatusBadge extends StatelessWidget {
  final _AssessmentTier tier;

  const _StatusBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tier.color,
        ),
      ),
    );
  }
}
