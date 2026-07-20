import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_outline_button.dart';

void main() {
  testWidgets('bottom sheet mendukung label aksi konfirmasi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiwaBottomSheet(
            title: 'Hapus Foto Kelulusan?',
            resetText: 'Batal',
            applyText: 'Hapus',
            applyColor: Colors.red,
            content: const Text('Konfirmasi penghapusan'),
            onReset: () {},
            onApply: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hapus Foto Kelulusan?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
  });

  testWidgets('bottom sheet informasi dapat memakai satu tombol', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiwaBottomSheet(
            title: 'Informasi',
            applyText: 'Mengerti',
            content: const Text('Pesan informasi'),
            onApply: () {},
          ),
        ),
      ),
    );

    expect(find.text('Mengerti'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
    expect(find.byType(AiwaOutlineButton), findsNothing);
  });
}
