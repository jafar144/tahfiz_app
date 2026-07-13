import 'dart:math';

/// Satu kandidat aturan kuis beserta bobot relatif kemunculannya.
///
/// Contoh bobot `2, 1, 1` berarti peluang `50%, 25%, 25%` selama ketiga
/// kandidat tersebut valid. Jika suatu kandidat tidak valid untuk ayat/surah
/// aktif, kandidat itu dibuang dan peluang kandidat tersisa dinormalisasi.
class WeightedQuizRule<T> {
  final T value;
  final int weight;

  const WeightedQuizRule(this.value, this.weight) : assert(weight > 0);
}

/// Utilitas tunggal untuk semua undian berbobot dalam kuis.
///
/// Saat fitur tingkat kesulitan ditambahkan, tiap profil cukup menyediakan
/// daftar [WeightedQuizRule] yang berbeda tanpa mengubah generator soal.
class WeightedQuizPicker {
  WeightedQuizPicker._();

  static T pick<T>(List<WeightedQuizRule<T>> rules, Random rng) {
    if (rules.isEmpty) {
      throw ArgumentError.value(rules, 'rules', 'Tidak boleh kosong.');
    }

    final totalWeight = rules.fold<int>(0, (sum, rule) => sum + rule.weight);
    var roll = rng.nextInt(totalWeight);
    for (final rule in rules) {
      roll -= rule.weight;
      if (roll < 0) return rule.value;
    }
    return rules.last.value;
  }

  /// Persentase teoretis [value] di dalam [rules], sebelum mempertimbangkan
  /// ketersediaan data, batas surah, atau fallback generator.
  static double probabilityPercent<T>(
    List<WeightedQuizRule<T>> rules,
    T value,
  ) {
    final totalWeight = rules.fold<int>(0, (sum, rule) => sum + rule.weight);
    if (totalWeight == 0) return 0;
    final valueWeight = rules
        .where((rule) => rule.value == value)
        .fold<int>(0, (sum, rule) => sum + rule.weight);
    return valueWeight * 100 / totalWeight;
  }
}
