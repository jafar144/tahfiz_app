import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/graduation_milestone_field.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/curriculum.dart';

void main() {
  testWidgets('picker hanya menampilkan capaian kelas yang diberikan', (
    tester,
  ) async {
    final choices = khoirunnasyienCurriculum.graduationMilestonesFor(
      'Tahsin Awwal',
    );
    GraduationMilestone? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraduationMilestoneField(
            className: 'Tahsin Awwal',
            milestones: choices,
            selected: null,
            enabled: true,
            promotionFor: (milestone) => khoirunnasyienCurriculum
                .graduationPromotionFor('Tahsin Awwal', milestone),
            onSelected: (value) async {
              selected = value;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('graduation-milestone-field')));
    await tester.pumpAndSettle();

    expect(find.text('Tahsin Awwal • 3 pilihan'), findsOneWidget);
    expect(find.text("Iqro' 1"), findsOneWidget);
    expect(find.text("Iqro' 3"), findsOneWidget);
    expect(find.text("Iqro' 4"), findsNothing);
    expect(
      find.text('Menuntaskan kelas • naik ke Tahsin Akhir'),
      findsOneWidget,
    );

    await tester.tap(find.text("Iqro' 2"));
    await tester.pumpAndSettle();
    expect(selected?.number, 2);
  });
}
