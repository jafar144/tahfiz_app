import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_reminder_schedule.dart';

class PaymentReminderScheduleCard extends StatelessWidget {
  final PaymentReminderSchedule schedule;
  final VoidCallback onTap;

  const PaymentReminderScheduleCard({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('payment_reminder_schedule_card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDCEBFF),
                foregroundColor: Color(0xFF2563EB),
                child: Icon(Icons.schedule_send_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Reminder WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tanggal ${schedule.firstDay}–${schedule.lastDay} • '
                      'jeda ${schedule.minIntervalMinutes}–'
                      '${schedule.maxIntervalMinutes} menit',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${schedule.items.length}',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentReminderScheduleSheet extends StatelessWidget {
  final PaymentReminderSchedule schedule;

  const PaymentReminderScheduleSheet({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Text(
            'Jadwal Reminder Pembayaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Text(
              'Setiap santri hanya mendapat satu reminder. Jadwal disusun '
              'deterministik dalam zona WIB.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          if (schedule.invalidPhoneCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${schedule.invalidPhoneCount} nomor wali perlu diperiksa; '
                '${schedule.adminFallbackCount} dialihkan ke admin.',
                style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            ),
          Expanded(
            child: schedule.items.isEmpty
                ? const Center(
                    child: Text('Tidak ada reminder yang perlu dijadwalkan.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: schedule.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = schedule.items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(item.santriName),
                        subtitle: Text(
                          '${item.typeLabel} • jeda ${item.intervalMinutes} menit',
                        ),
                        trailing: Text(
                          DateFormat(
                            'd MMM\nHH:mm',
                            'id_ID',
                          ).format(item.scheduledAt),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
