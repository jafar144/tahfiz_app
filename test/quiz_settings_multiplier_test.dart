import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_intro_view.dart';

void main() {
  testWidgets('setelan latihan menampilkan multiplier mode dan kesulitan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizIntroView(
            settings: const QuizSettings(),
            onSettingsChanged: (_) {},
            onStart: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Bacakan lanjutannya · Poin ×2'), findsOneWidget);
    expect(find.text('6 opsi · 60 detik · Poin ×1'), findsOneWidget);
    expect(find.text('Poin ×1'), findsOneWidget);
    expect(find.text('Poin ×1.5'), findsOneWidget);
    expect(find.text('Poin ×2'), findsOneWidget);
  });
}
