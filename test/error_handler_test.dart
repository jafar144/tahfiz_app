import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler.functionsMessage', () {
    test('getMessage mempertahankan pesan validasi dari callable', () {
      final error = FirebaseFunctionsException(
        code: 'already-exists',
        message: 'NIS 1001 sudah mempunyai akun.',
      );

      expect(
        ErrorHandler.getMessage(error),
        'NIS 1001 sudah mempunyai akun.',
      );
    });

    test('mempertahankan pesan validasi dari callable', () {
      expect(
        ErrorHandler.functionsMessage(
          code: 'already-exists',
          message: 'NIS 1001 sudah mempunyai akun.',
        ),
        'NIS 1001 sudah mempunyai akun.',
      );
    });

    test('memberi fallback yang jelas saat server tidak mengirim pesan', () {
      expect(
        ErrorHandler.functionsMessage(code: 'already-exists'),
        'NIS sudah mempunyai akun. Gunakan NIS lain.',
      );
      expect(
        ErrorHandler.functionsMessage(code: 'permission-denied'),
        'Hanya admin yang dapat melakukan tindakan ini.',
      );
    });
  });
}
