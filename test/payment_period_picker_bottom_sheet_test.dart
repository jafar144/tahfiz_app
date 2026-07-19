import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_period_picker_bottom_sheet.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('picker menyembunyikan periode sebelum Februari 2026', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentPeriodPickerBottomSheet(
            initialDate: DateTime(2026, 1),
            now: DateTime(2026, 7),
          ),
        ),
      ),
    );

    expect(find.text('Pilih Periode Pembayaran'), findsOneWidget);
    expect(
      find.text('Pencatatan pembayaran tersedia mulai Februari 2026.'),
      findsOneWidget,
    );
    expect(find.text('Januari'), findsNothing);
    expect(find.text('Februari'), findsOneWidget);
    expect(find.text('2025'), findsNothing);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2027'), findsOneWidget);
  });
}
