import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/features/payment/data/models/payment_reminder_schedule_model.dart';
import 'package:khoirunnasyien/features/payment/data/payment_scheduling_service.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_reminder_schedule.dart';
import 'package:khoirunnasyien/features/payment/presentation/pages/payment_scheduling_page.dart';

class FakeSchedulingService implements PaymentSchedulingService {
  List<PaymentReminderScheduleItem> items = [
    const PaymentReminderScheduleItem(
      santriId: 'a',
      santriName: 'Ahmad',
      type: 'current-month-payment',
      scheduledAt: null,
      intervalMinutes: 0,
      arrearsCount: 1,
      canSend: true,
    ),
    const PaymentReminderScheduleItem(
      santriId: 'b',
      santriName: 'Budi',
      type: 'two-month-arrears',
      scheduledAt: null,
      intervalMinutes: 0,
      arrearsCount: 2,
      status: 'sent',
      whatsappStatus: 'sent',
      appStatus: 'sent',
    ),
    const PaymentReminderScheduleItem(
      santriId: 'c',
      santriName: 'Cahya',
      type: 'arrears',
      scheduledAt: null,
      intervalMinutes: 0,
      arrearsCount: 4,
      status: 'failed',
      canSend: true,
    ),
  ];
  final sent = <(DateTime, String)>[];
  Object? error;

  @override
  Future<PaymentReminderSchedule> load(DateTime period) async {
    if (error != null) throw error!;
    return PaymentReminderSchedule(
      firstDay: 25,
      lastDay: 31,
      minIntervalMinutes: 1,
      maxIntervalMinutes: 15,
      invalidPhoneCount: 0,
      adminFallbackCount: 0,
      items: items,
    );
  }

  @override
  Future<DateTime?> send(DateTime period, String santriId) async {
    sent.add((period, santriId));
    return DateTime.utc(2026, 11, 1, 1, 10);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> showPage(
    WidgetTester tester,
    FakeSchedulingService service,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentSchedulingPage(
          service: service,
          initialPeriod: DateTime(2026, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'kelompok tunggakan, filter status, pencarian, dan tidak overflow pada layar kecil',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showPage(tester, FakeSchedulingService());
      expect(find.text('Penjadwalan Pembayaran'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tunggakan 3 bulan atau lebih (1)'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tunggakan 3 bulan atau lebih (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(TextField),
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'Budi');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Budi',
        ),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Budi',
        ),
        findsOneWidget,
      );
      expect(find.text('Ahmad'), findsNothing);
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Belum terkirim'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Belum terkirim'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Budi',
        ),
        findsNothing,
      );
      expect(find.text('Tidak ada santri pada filter ini.'), findsOneWidget);
    },
  );

  testWidgets(
    'manual memerlukan konfirmasi, memakai periode pilihan, lalu memperbarui status',
    (tester) async {
      final service = FakeSchedulingService();
      await showPage(tester, service);
      final sendButton = find.byKey(const ValueKey('send-a'));
      await tester.scrollUntilVisible(
        sendButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(service.sent, isEmpty);
      expect(find.text('Kirim pengingat pembayaran?'), findsOneWidget);
      await tester.tap(find.text('Jadwalkan'));
      await tester.pumpAndSettle();
      expect(service.sent, [(DateTime(2026, 10), 'a')]);
      expect(find.text('Dijadwalkan 1 Nov, 08:10 WIB.'), findsOneWidget);
    },
  );

  testWidgets(
    'refresh menghilangkan santri lunas dan menampilkan keadaan kosong',
    (tester) async {
      final service = FakeSchedulingService();
      await showPage(tester, service);
      service.items = [];
      await tester.tap(find.byTooltip('Perbarui status'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada tunggakan pada periode ini.'),
        findsOneWidget,
      );
      expect(find.text('Ahmad'), findsNothing);
    },
  );

  testWidgets('kegagalan memuat dapat dicoba ulang', (tester) async {
    final service = FakeSchedulingService()
      ..error = Exception('Koneksi terputus');
    await showPage(tester, service);
    expect(find.text('Koneksi terputus'), findsOneWidget);
    service.error = null;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi terputus'), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
  });

  test(
    'model menerima status tanpa jadwal dan waktu ditampilkan dalam WIB',
    () {
      final model = PaymentReminderScheduleModel.fromMap({
        'items': [
          {
            'santriId': 'x',
            'santriName': 'Uji',
            'status': 'pending',
            'scheduledAt': null,
            'arrearsCount': 2,
            'canSend': true,
          },
          {
            'santriId': 'y',
            'santriName': 'Uji admin',
            'status': 'sent',
            'whatsappStatus': 'sent',
            'adminFallback': true,
            'scheduledAt': '2026-10-25T01:05:00Z',
          },
        ],
      });
      expect(model.firstDay, 25);
      expect(model.maxIntervalMinutes, 15);
      expect(model.pendingCount, 2);
      expect(model.items.first.scheduledAt, isNull);
      expect(model.items.first.group, 2);
      expect(
        PaymentReminderScheduleItem.wib(model.items.last.scheduledAt!).hour,
        8,
      );
    },
  );
}
