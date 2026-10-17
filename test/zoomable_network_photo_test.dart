import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/widgets/zoomable_network_photo.dart';

void main() {
  testWidgets('foto dibuka dalam viewer yang dapat dizoom', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showZoomableNetworkPhoto(
                context,
                imageUrl: 'https://example.com/photo.jpg',
                semanticLabel: 'Foto profil Ahmad',
              ),
              child: const Text('Buka foto'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka foto'));
    await tester.pump();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('Tutup foto'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup foto'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
