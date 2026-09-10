import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_reminder_schedule.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_reminder_schedule_card.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('admin dapat membuka rincian jadwal reminder', (tester) async {
    final schedule = PaymentReminderSchedule(
      firstDay: 20,
      lastDay: 30,
      minIntervalMinutes: 1,
      maxIntervalMinutes: 20,
      invalidPhoneCount: 0,
      adminFallbackCount: 0,
      items: [
        PaymentReminderScheduleItem(
          santriId: 'santri-1',
          santriName: 'Ahmad',
          type: 'current-month-payment',
          scheduledAt: DateTime(2026, 9, 22, 8, 14),
          intervalMinutes: 14,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentReminderScheduleCard(
            schedule: schedule,
            onTap: () => showModalBottomSheet<void>(
              context: tester.element(
                find.byKey(const Key('payment_reminder_schedule_card')),
              ),
              builder: (_) => SizedBox(
                height: 500,
                child: PaymentReminderScheduleSheet(schedule: schedule),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tanggal 20–30 • jeda 1–20 menit'), findsOneWidget);
    await tester.tap(find.byKey(const Key('payment_reminder_schedule_card')));
    await tester.pumpAndSettle();

    expect(find.text('Ahmad'), findsOneWidget);
    expect(find.textContaining('Tagihan bulan berjalan'), findsOneWidget);
  });
}
