import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';

void main() {
  test('periode pembayaran dimulai dari Februari 2026', () {
    expect(
      PaymentUtils.clampToSupportedPeriod(DateTime(2026, 1)),
      DateTime(2026, 2),
    );
    expect(PaymentUtils.availablePaymentYears(now: DateTime(2026, 7)), [
      2026,
      2027,
    ]);
    expect(PaymentUtils.availablePaymentMonths(2026), [
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
    ]);
    expect(PaymentUtils.availablePaymentMonths(2025), isEmpty);
  });

  test('awal pembayaran tidak pernah sebelum bulan tanggal masuk', () {
    final result = PaymentUtils.resolveStartDate(
      freeUntil: DateTime(2020, 12, 31),
      tanggalMasuk: DateTime(2026, 7, 19),
    );

    expect(result, DateTime(2026, 7));
  });

  test('tanggal masuk wajib tersedia untuk menghitung awal pembayaran', () {
    final result = PaymentUtils.resolveStartDate(
      freeUntil: DateTime(2020, 12, 31),
      tanggalMasuk: null,
    );

    expect(result, isNull);
    expect(
      PaymentUtils.isEnrolledInMonth(tanggalMasuk: null, month: 7, year: 2026),
      isFalse,
    );
    expect(
      PaymentUtils.isEnrolledInMonth(
        tanggalMasuk: DateTime(2026, 7, 19),
        month: 6,
        year: 2026,
      ),
      isFalse,
    );
  });
}
