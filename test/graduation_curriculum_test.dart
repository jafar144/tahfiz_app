import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/curriculum.dart';

void main() {
  const curriculum = khoirunnasyienCurriculum;

  test('kurikulum kelulusan berisi tepat 72 capaian berurutan', () {
    final milestones = curriculum.graduationMilestones;

    expect(milestones, hasLength(72));
    expect(
      milestones.map((item) => item.number),
      orderedEquals(List<int>.generate(72, (index) => index + 1)),
    );
    expect(milestones.map((item) => item.label).toSet(), hasLength(72));
  });

  test('pilihan capaian dibatasi oleh rentang kelas santri', () {
    final expectedRanges = <String, (int, int)>{
      'Tahsin Awwal': (1, 3),
      'Tahsin Akhir': (4, 6),
      'Mutawassith': (7, 24),
      'Pra Takhossus Awal': (25, 31),
      'Pra Takhossus Akhir': (32, 37),
      'Takhossus Awal': (38, 44),
      'Takhossus Tsani': (45, 50),
      'Takhossus Tsalits': (51, 56),
      'Takhossus Robi': (57, 62),
      'Takhossus Khomis': (63, 68),
      'Takhossus Akhir': (69, 72),
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

    expect(choices.first.number, 57);
    expect(choices.last.number, 62);
  });

  test('capaian terakhir menghasilkan transisi kecuali kelas final', () {
    final juz30 = curriculum.graduationMilestones.singleWhere(
      (item) => item.number == 24,
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
