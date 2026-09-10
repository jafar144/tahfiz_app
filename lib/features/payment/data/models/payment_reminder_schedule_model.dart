import 'package:khoirunnasyien/features/payment/domain/entities/payment_reminder_schedule.dart';

class PaymentReminderScheduleModel {
  const PaymentReminderScheduleModel._();

  static PaymentReminderSchedule fromMap(Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          return PaymentReminderScheduleItem(
            santriId: (item['santriId'] as String?)?.trim() ?? '',
            santriName: (item['santriName'] as String?)?.trim() ?? 'Santri',
            type: (item['type'] as String?)?.trim() ?? 'current-month-payment',
            scheduledAt: DateTime.parse(
              item['scheduledAt'] as String,
            ).toLocal(),
            intervalMinutes: (item['intervalMinutes'] as num?)?.toInt() ?? 1,
          );
        })
        .toList(growable: false);

    return PaymentReminderSchedule(
      firstDay: (data['firstDay'] as num?)?.toInt() ?? 20,
      lastDay: (data['lastDay'] as num?)?.toInt() ?? 31,
      minIntervalMinutes: (data['minIntervalMinutes'] as num?)?.toInt() ?? 1,
      maxIntervalMinutes: (data['maxIntervalMinutes'] as num?)?.toInt() ?? 20,
      invalidPhoneCount: (data['invalidPhoneCount'] as num?)?.toInt() ?? 0,
      adminFallbackCount: (data['adminFallbackCount'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }
}
