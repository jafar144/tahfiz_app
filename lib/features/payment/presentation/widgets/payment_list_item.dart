import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

class PaymentListItem extends StatelessWidget {
  final PaymentEntity payment;
  final VoidCallback? onTap;

  const PaymentListItem({
    super.key,
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = payment.santriName ?? 'Unknown';
    final amount = payment.total;
    final date = payment.createdAt;
    
    // Safety check for int parsing if month is string number
    final monthInt = int.tryParse(payment.bulan) ?? 1;
    
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '+Rp ',
      decimalDigits: 0,
    );
    final timeStr = DateFormat('HH:mm').format(date);
    final dateStr = DateFormat('d MMM').format(date);
    final monthName = DateFormat('MMMM', 'id_ID').format(DateTime(2024, monthInt));
    final year = DateFormat('yyyy').format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
              child: Text(
                UiUtils.getInitials(name),
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SPP $monthName $year',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency.format(amount),
                  style: const TextStyle(
                    color: Color(0xFF0CAF60),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr • $timeStr',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
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
