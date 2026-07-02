import 'package:equatable/equatable.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Setelan sesi kuis yang dipilih santri sebelum mulai.
class QuizSettings extends Equatable {
  /// Mode permainan: suara (Whisper) atau pilihan ganda.
  final QuizMode mode;

  /// Juz yang diikutkan (subset dari {29, 30}), minimal satu.
  final Set<int> juz;

  /// Sertakan soal sambungan antar surah — jawaban boleh masuk ke awal surah
  /// berikutnya (basmalah diikutkan otomatis, khusus mode suara).
  final bool crossSurah;

  const QuizSettings({
    this.mode = QuizMode.voice,
    this.juz = const {29, 30},
    this.crossSurah = true,
  });

  /// Daftar juz terurut menaik (untuk penyimpanan & tampilan).
  List<int> get sortedJuz => juz.toList()..sort();

  QuizSettings copyWith({QuizMode? mode, Set<int>? juz, bool? crossSurah}) =>
      QuizSettings(
        mode: mode ?? this.mode,
        juz: juz ?? this.juz,
        crossSurah: crossSurah ?? this.crossSurah,
      );

  @override
  List<Object?> get props => [mode, juz, crossSurah];
}
