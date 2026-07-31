import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/kelulusan_save_banner.dart';

void main() {
  Widget buildBanner(
    KelulusanSaveStatus status, {
    String? failureMessage,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: KelulusanSaveBanner(
          status: status,
          failureMessage: failureMessage,
          onRetry: onRetry,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  testWidgets('status menyimpan menunggu sebelum membuka menu bagikan', (
    tester,
  ) async {
    await tester.pumpWidget(buildBanner(KelulusanSaveStatus.saving));

    expect(find.text('Menyimpan foto kelulusan…'), findsOneWidget);
    expect(find.textContaining('dibagikan setelah tersimpan'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('status berhasil menampilkan konfirmasi penyimpanan', (
    tester,
  ) async {
    await tester.pumpWidget(buildBanner(KelulusanSaveStatus.success));

    expect(find.text('Foto kelulusan sudah tersimpan'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('status gagal dapat mencoba kembali', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      buildBanner(KelulusanSaveStatus.failure, onRetry: () => retried = true),
    );

    await tester.tap(find.text('Coba Lagi'));

    expect(retried, isTrue);
  });

  testWidgets('status gagal dapat menampilkan pesan jaringan khusus', (
    tester,
  ) async {
    const message =
        'Tidak ada koneksi internet. Periksa jaringan Anda, lalu coba lagi.';
    await tester.pumpWidget(
      buildBanner(KelulusanSaveStatus.failure, failureMessage: message),
    );

    expect(find.text(message), findsOneWidget);
  });
}
