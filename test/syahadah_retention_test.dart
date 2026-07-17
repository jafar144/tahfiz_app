import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/syahadah/data/syahadah_retention.dart';

DateTime _wibToUtc(int year, int month, int day, int hour) {
  return DateTime.utc(
    year,
    month,
    day,
    hour,
  ).subtract(const Duration(hours: 7));
}

void main() {
  test('foto tidak aktif setelah lewat tujuh hari', () {
    final createdAt = _wibToUtc(2026, 7, 8, 10);

    expect(
      isSyahadahPhotoActive(createdAt, now: _wibToUtc(2026, 7, 15, 10)),
      isTrue,
    );
    expect(
      isSyahadahPhotoActive(
        createdAt,
        now: _wibToUtc(2026, 7, 15, 10).add(const Duration(seconds: 1)),
      ),
      isFalse,
    );
  });

  test('foto 8 Juli dijadwalkan terhapus Senin 20 Juli', () {
    final scheduled = syahadahScheduledDeletionAtUtc(
      _wibToUtc(2026, 7, 8, 10),
      now: _wibToUtc(2026, 7, 17, 12),
    );

    expect(scheduled, _wibToUtc(2026, 7, 20, 3));
  });

  test('jadwal tepat pada batas tujuh hari menunggu Senin berikutnya', () {
    final scheduled = syahadahScheduledDeletionAtUtc(
      _wibToUtc(2026, 7, 13, 3),
      now: _wibToUtc(2026, 7, 17, 12),
    );

    expect(scheduled, _wibToUtc(2026, 7, 27, 3));
  });

  test('record yang melewatkan jadwal memakai jadwal Senin berikutnya', () {
    final scheduled = syahadahScheduledDeletionAtUtc(
      _wibToUtc(2026, 7, 1, 10),
      now: _wibToUtc(2026, 7, 21, 12),
    );

    expect(scheduled, _wibToUtc(2026, 7, 27, 3));
  });
}
