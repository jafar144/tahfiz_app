import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/syahadah_template.dart';

void main() {
  testWidgets('kanvas syahadah mengabaikan pembesaran font perangkat', (
    tester,
  ) async {
    double? effectiveTextSize;
    SyahadahTemplateRegistry.configure(
      (_) => Builder(
        builder: (context) {
          effectiveTextSize = MediaQuery.textScalerOf(context).scale(20);
          return const SizedBox(width: 1080, height: 1350);
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: SyahadahTemplate(
              displayName: 'Zahira Alya R',
              nis: '4110',
              hafalan: 'Ad-Dhuha sampai An-Nas',
              photoUrl: 'https://example.com/photo.jpg',
              kelas: 'Mutawassith',
              date: DateTime(2026, 7),
            ),
          ),
        ),
      ),
    );

    expect(effectiveTextSize, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blok hafalan panjang mengecil di dalam frame tetap', (
    tester,
  ) async {
    const longText =
        'Lancar dan Lulus\n'
        'HAFALAN AL-QURAN\n'
        'Ad-Dhuha sampai An-Nas dengan tambahan keterangan yang sangat '
        'panjang agar melebihi area poster';

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SyahadahFittedText(
              text: longText,
              width: 500,
              height: 245,
              style: TextStyle(fontSize: 50, height: 1.4),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(SyahadahFittedText)),
      const Size(500, 245),
    );

    final fittedBox = tester.renderObject<RenderFittedBox>(
      find.byType(FittedBox),
    );
    expect(fittedBox.child!.size.height, greaterThan(fittedBox.size.height));

    final renderedText = tester.widget<Text>(find.text(longText));
    expect(renderedText.textScaler!.scale(50), 50);
    expect(tester.takeException(), isNull);
  });
}
