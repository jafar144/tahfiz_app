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
            scheduledAt: _date(item['scheduledAt']),
            intervalMinutes: (item['intervalMinutes'] as num?)?.toInt() ?? 1,
            arrearsCount: (item['arrearsCount'] as num?)?.toInt() ?? 1,
            months: (item['months'] as List<dynamic>? ?? []).map((raw) {
              final month = Map<String, dynamic>.from(raw as Map);
              return DateTime(
                (month['year'] as num).toInt(),
                (month['month'] as num).toInt(),
              );
            }).toList(),
            status: item['status'] as String? ?? 'pending',
            whatsappStatus: item['whatsappStatus'] as String? ?? 'pending',
            appStatus: item['appStatus'] as String? ?? 'pending',
            adminFallback: item['adminFallback'] == true,
            estimated: item['estimated'] != false,
            canSend: item['canSend'] == true,
            sentAt: _date(item['sentAt']),
            attempts: (item['attempts'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);

    return PaymentReminderSchedule(
      firstDay: (data['firstDay'] as num?)?.toInt() ?? 25,
      lastDay: (data['lastDay'] as num?)?.toInt() ?? 31,
      minIntervalMinutes: (data['minIntervalMinutes'] as num?)?.toInt() ?? 1,
      maxIntervalMinutes: (data['maxIntervalMinutes'] as num?)?.toInt() ?? 15,
      invalidPhoneCount: (data['invalidPhoneCount'] as num?)?.toInt() ?? 0,
      adminFallbackCount: (data['adminFallbackCount'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
