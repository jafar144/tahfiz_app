import 'package:equatable/equatable.dart';

/// Setelan sesi kuis yang dipilih santri sebelum mulai.
class QuizSettings extends Equatable {
  /// Juz yang diikutkan (subset dari {29, 30}), minimal satu.
  final Set<int> juz;

  /// Sertakan soal sambungan antar surah — jawaban boleh masuk ke awal surah
  /// berikutnya (basmalah diikutkan otomatis).
  final bool crossSurah;

  const QuizSettings({
    this.juz = const {29, 30},
    this.crossSurah = true,
  });

  /// Daftar juz terurut menaik (untuk penyimpanan & tampilan).
  List<int> get sortedJuz => juz.toList()..sort();

  QuizSettings copyWith({Set<int>? juz, bool? crossSurah}) => QuizSettings(
        juz: juz ?? this.juz,
        crossSurah: crossSurah ?? this.crossSurah,
      );

  @override
  List<Object?> get props => [juz, crossSurah];
}
