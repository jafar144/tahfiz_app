import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_santri/domain/services/santri_birth_date_policy.dart';

void main() {
  test('perubahan tanggal lahir memerlukan reset password', () {
    expect(
      SantriBirthDatePolicy.requiresPasswordReset(
        previous: DateTime(2012, 3, 8),
        next: DateTime(2012, 3, 9),
      ),
      isTrue,
    );
  });

  test('perubahan field lain tidak memerlukan reset password', () {
    expect(
      SantriBirthDatePolicy.requiresPasswordReset(
        previous: DateTime(2012, 3, 9, 10),
        next: DateTime(2012, 3, 9, 18),
      ),
      isFalse,
    );
  });

  test('reset gagal dapat dicoba lagi melalui pending marker', () {
    expect(
      SantriBirthDatePolicy.requiresPasswordReset(
        previous: DateTime(2012, 3, 9),
        next: DateTime(2012, 3, 9),
        pendingDateKey: '2012-03-09',
      ),
      isTrue,
    );
  });
}
