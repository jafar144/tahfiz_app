import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';

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
}
