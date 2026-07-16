import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';

void main() {
  testWidgets(
    'card ringkas, detail berupa badge ikon, dan indikator tersusun vertikal',
    (tester) async {
      var displayIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return InfoCard(
                    title: 'Santri Putra',
                    value: '120',
                    color: Colors.blue,
                    displayIndex: displayIndex,
                    details: const [
                      InfoCardDetail(
                        label: 'Sore',
                        value: 72,
                        icon: Icons.wb_twilight,
                        color: Colors.deepOrange,
                      ),
                      InfoCardDetail(
                        label: 'Malam',
                        value: 48,
                        icon: Icons.nights_stay_outlined,
                        color: Colors.indigo,
                      ),
                    ],
                    masuk: 3,
                    keluar: 1,
                    onTap: () =>
                        setState(() => displayIndex = (displayIndex + 1) % 3),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(InfoCard)).width, 140);
      expect(find.text('Santri Putra'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      final indicatorSize = tester.getSize(
        find.byKey(const ValueKey('info-card-face-indicator')),
      );
      expect(indicatorSize.height, greaterThan(indicatorSize.width));

      await tester.tap(find.byType(InfoCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      final verticalOffsets = tester
          .widgetList<SlideTransition>(find.byType(SlideTransition))
          .map((transition) => transition.position.value.dy)
          .toList();
      expect(
        verticalOffsets.any((offset) => offset > 0.01),
        isTrue,
        reason: 'Konten lama harus turun dari tengah menuju bawah.',
      );
      expect(
        verticalOffsets.any((offset) => offset < -0.01),
        isTrue,
        reason: 'Konten baru harus turun dari atas menuju tengah.',
      );

      await tester.pumpAndSettle();
      expect(find.text('Rincian Sesi'), findsNothing);
      expect(find.byIcon(Icons.wb_twilight), findsOneWidget);
      expect(find.text('Sore'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.byIcon(Icons.nights_stay_outlined), findsOneWidget);
      expect(find.text('Malam'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);

      await tester.tap(find.byType(InfoCard));
      await tester.pumpAndSettle();
      expect(find.text('30 hari terakhir'), findsNothing);
      expect(find.text('30 hari'), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsNothing);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
      expect(find.text('Masuk'), findsNothing);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.person_remove_alt_1_rounded), findsOneWidget);
      expect(find.text('Keluar'), findsNothing);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byType(InfoCard));
      await tester.pumpAndSettle();
      expect(find.text('Santri Putra'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    },
  );
}
