import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';

void main() {
  testWidgets(
    'card sedikit lebih lebar, bisa diketuk, dan seluruh transisi bergerak turun',
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
                      InfoCardDetail(label: 'Sore', value: 72),
                      InfoCardDetail(label: 'Malam', value: 48),
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

      expect(tester.getSize(find.byType(InfoCard)).width, 152);
      expect(find.text('Santri Putra'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);

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
      expect(find.text('Rincian Sesi'), findsOneWidget);
      expect(find.text('Sore'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('Malam'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);

      await tester.tap(find.byType(InfoCard));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mutasi'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byType(InfoCard));
      await tester.pumpAndSettle();
      expect(find.text('Santri Putra'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    },
  );
}
