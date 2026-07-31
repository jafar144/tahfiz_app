import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/syahadah/data/kelulusan_repository.dart';

void main() {
  group('mapKelulusanFunctionsError', () {
    test('mengubah raw endpoint NOT_FOUND menjadi pesan Indonesia', () {
      final result = mapKelulusanFunctionsError(
        code: 'not-found',
        message: ' NOT_FOUND ',
      );

      expect(result, isA<KelulusanRemoteException>());
      final error = result as KelulusanRemoteException;
      expect(error.message, kelulusanFeatureUnavailableMessage);
      expect(error.code, 'not-found');
    });

    test('tetap mempertahankan pesan not-found bisnis dari handler', () {
      const businessMessage = 'Data santri tidak ditemukan.';

      final result = mapKelulusanFunctionsError(
        code: 'not-found',
        message: businessMessage,
      );

      expect(result, isA<KelulusanRemoteException>());
      final error = result as KelulusanRemoteException;
      expect(error.message, businessMessage);
      expect(error.code, 'not-found');
    });

    test('mapping already-exists dan detail jumlah tetap sama', () {
      final result = mapKelulusanFunctionsError(
        code: 'already-exists',
        message: 'Foto sudah ada.',
        details: const {'existingCount': 3},
      );

      expect(result, isA<KelulusanAlreadyExistsException>());
      final error = result as KelulusanAlreadyExistsException;
      expect(error.message, 'Foto sudah ada.');
      expect(error.existingCount, 3);
    });

    test('mapping unavailable tetap dianggap gangguan jaringan', () {
      final result = mapKelulusanFunctionsError(
        code: 'unavailable',
        message: 'UNAVAILABLE',
      );

      expect(result, isA<KelulusanNetworkException>());
      expect(
        (result as KelulusanNetworkException).message,
        kelulusanNetworkErrorMessage,
      );
    });
  });
}
