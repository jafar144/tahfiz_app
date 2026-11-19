import 'package:cloud_functions/cloud_functions.dart';
import 'package:khoirunnasyien/features/payment/data/models/payment_reminder_schedule_model.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_reminder_schedule.dart';

abstract interface class PaymentSchedulingService {
  Future<PaymentReminderSchedule> load(DateTime period);
  Future<DateTime?> send(DateTime period, String santriId);
}

class FirebasePaymentSchedulingService implements PaymentSchedulingService {
  final FirebaseFunctions functions;
  FirebasePaymentSchedulingService(this.functions);

  @override
  Future<PaymentReminderSchedule> load(DateTime period) async {
    final result = await functions
        .httpsCallable(
          'getPaymentReminderSchedule',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
        )
        .call({'year': period.year, 'month': period.month});
    return PaymentReminderScheduleModel.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  @override
  Future<DateTime?> send(DateTime period, String santriId) async {
    final result = await functions
        .httpsCallable(
          'sendManualPaymentReminder',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
        )
        .call({
          'year': period.year,
          'month': period.month,
          'santriId': santriId,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['scheduledAt'] is String
        ? DateTime.parse(data['scheduledAt'] as String)
        : null;
  }
}
