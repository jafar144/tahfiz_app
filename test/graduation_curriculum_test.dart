import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/curriculum.dart';

void main() {
  const curriculum = khoirunnasyienCurriculum;

  test('kurikulum kelulusan berisi tepat 73 capaian berurutan', () {
    final milestones = curriculum.graduationMilestones;

    expect(milestones, hasLength(73));
    expect(
      milestones.map((item) => item.number),
      orderedEquals(List<int>.generate(73, (index) => index + 1)),
    );
    expect(milestones.map((item) => item.label).toSet(), hasLength(73));
  });

  test('pilihan capaian dibatasi oleh rentang kelas santri', () {
    final expectedRanges = <String, (int, int)>{
      'Tahsin Awwal': (1, 3),
      'Tahsin Akhir': (4, 6),
      'Mutawassith': (7, 25),
      'Pra Takhossus Awal': (26, 32),
      'Pra Takhossus Akhir': (33, 38),
      'Takhossus Awal': (39, 45),
      'Takhossus Tsani': (46, 51),
      'Takhossus Tsalits': (52, 57),
      'Takhossus Robi': (58, 63),
      'Takhossus Khomis': (64, 69),
      'Takhossus Akhir': (70, 73),
    };

    for (final MapEntry(key: className, value: range)
        in expectedRanges.entries) {
      final choices = curriculum.graduationMilestonesFor(className);
      expect(choices.first.number, range.$1, reason: className);
      expect(choices.last.number, range.$2, reason: className);
      expect(choices, hasLength(range.$2 - range.$1 + 1), reason: className);
    }
  });

  test('nama Rabi lama dinormalisasi ke kelas Robi', () {
    final choices = curriculum.graduationMilestonesFor('Takhossus Rabi');

    expect(choices.first.number, 58);
    expect(choices.last.number, 63);
  });

  test('capaian terakhir menghasilkan transisi kecuali kelas final', () {
    final juz30 = curriculum.graduationMilestones.singleWhere(
      (item) => item.number == 25,
    );
    final promotion = curriculum.graduationPromotionFor('Mutawassith', juz30);

    expect(promotion?.fromClass, 'Mutawassith');
    expect(promotion?.toClass, 'Pra Takhossus Awal');

    final tahqiq = curriculum.graduationMilestones.last;
    expect(
      curriculum.graduationPromotionFor('Takhossus Akhir', tahqiq),
      isNull,
    );
  });
}
