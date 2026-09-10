import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/utils/whatsapp_utils.dart';

void main() {
  group('WhatsAppUtils.normalizePhone', () {
    final validFormats = <String, String>{
      '0812-3456-7890': '6281234567890',
      '+62 812 3456 7890': '6281234567890',
      '0062 812 3456 7890': '6281234567890',
      '+62 (0) 812-3456-7890': '6281234567890',
      '81234567890': '6281234567890',
    };

    for (final entry in validFormats.entries) {
      test('menerima format ${entry.key}', () {
        expect(WhatsAppUtils.normalizePhone(entry.key), entry.value);
      });
    }

    test('menolak nomor kosong, terlalu pendek, dan non-seluler', () {
      expect(WhatsAppUtils.normalizePhone(null), isNull);
      expect(WhatsAppUtils.normalizePhone(''), isNull);
      expect(WhatsAppUtils.normalizePhone('0812'), isNull);
      expect(WhatsAppUtils.normalizePhone('021 555 1234'), isNull);
    });
  });

  test('buildUri menyusun URL WhatsApp dan pesan secara aman', () {
    final uri = WhatsAppUtils.buildUri(
      '0812 3456 7890',
      message: 'Assalamu\'alaikum, Ustadz.',
    );

    expect(uri?.scheme, 'https');
    expect(uri?.host, 'wa.me');
    expect(uri?.path, '/6281234567890');
    expect(uri?.queryParameters['text'], 'Assalamu\'alaikum, Ustadz.');
  });

  group('WhatsAppUtils.launch', () {
    test('tidak memanggil launcher untuk nomor tidak valid', () async {
      var called = false;

      final result = await WhatsAppUtils.launch(
        'nomor tidak ada',
        launcher: (_) async {
          called = true;
          return true;
        },
      );

      expect(result, WhatsAppLaunchResult.invalidPhone);
      expect(called, isFalse);
    });

    test('mendeteksi launcher yang mengembalikan false', () async {
      final result = await WhatsAppUtils.launch(
        '081234567890',
        launcher: (_) async => false,
      );

      expect(result, WhatsAppLaunchResult.unavailable);
    });

    test('melaporkan sukses hanya ketika launcher benar-benar terbuka', () async {
      Uri? launchedUri;

      final result = await WhatsAppUtils.launch(
        '+62 (0) 812-3456-7890',
        launcher: (uri) async {
          launchedUri = uri;
          return true;
        },
      );

      expect(result, WhatsAppLaunchResult.opened);
      expect(launchedUri?.toString(), 'https://wa.me/6281234567890');
    });
  });
}
