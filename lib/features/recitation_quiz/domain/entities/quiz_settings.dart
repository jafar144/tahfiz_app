import 'package:equatable/equatable.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Setelan sesi kuis yang dipilih santri sebelum mulai. Disimpan ke penyimpanan
/// lokal agar tidak perlu diatur ulang tiap membuka kuis.
class QuizSettings extends Equatable {
  /// Mode permainan: suara (Whisper) atau pilihan ganda.
  final QuizMode mode;

  /// Juz yang diikutkan (subset dari [QuizJuz.supported]), minimal satu.
  final Set<int> juz;

  /// Surah AWAL rentang target hafalan per juz (id surah mushaf) — HANYA untuk
  /// juz "surah utuh" (29 & 30). Ujung akhir selalu dikunci ke surah terakhir
  /// juz; santri hanya mengatur surah awal. Bila sebuah juz tak punya entri,
  /// dianggap mulai dari surah pertama juz (rentang penuh). Juz "rentang ayat"
  /// (1-3) mengabaikan ini.
  final Map<int, int> rangeStart;

  const QuizSettings({
    this.mode = QuizMode.voice,
    this.juz = const {29, 30},
    this.rangeStart = const {},
  });

  /// Daftar juz terurut menaik (untuk penyimpanan & tampilan).
  List<int> get sortedJuz => juz.toList()..sort();

  /// Surah awal rentang target juz [j] (default: surah pertama juz). Untuk juz
  /// "rentang ayat" (tanpa kustomisasi), kembalikan surah awal segmen pertama.
  int startSurahFor(int j) {
    if (!QuizJuz.supportsCustomRange(j)) {
      final segs = QuizJuz.ayahSegments(j);
      return segs.isNotEmpty ? segs.first.$1 : j;
    }
    return QuizJuz.clampStart(j, rangeStart[j] ?? QuizJuz.firstSurah(j));
  }

  QuizSettings copyWith({
    QuizMode? mode,
    Set<int>? juz,
    Map<int, int>? rangeStart,
  }) => QuizSettings(
    mode: mode ?? this.mode,
    juz: juz ?? this.juz,
    rangeStart: rangeStart ?? this.rangeStart,
  );

  /// Setel surah awal rentang target untuk juz [j].
  QuizSettings withRangeStart(int j, int startSurah) {
    final next = Map<int, int>.from(rangeStart);
    next[j] = QuizJuz.clampStart(j, startSurah);
    return copyWith(rangeStart: next);
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.key,
    'juz': sortedJuz,
    'range_start': rangeStart.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory QuizSettings.fromJson(Map<String, dynamic> json) {
    final juzRaw = (json['juz'] as List?)?.whereType<num>().map(
      (e) => e.toInt(),
    );
    final juz = <int>{
      for (final j in (juzRaw ?? const <int>[]))
        if (QuizJuz.isSupported(j)) j,
    };
    final rangeRaw = (json['range_start'] as Map?) ?? const {};
    final rangeStart = <int, int>{};
    rangeRaw.forEach((k, v) {
      final j = int.tryParse(k.toString());
      final s = v is num ? v.toInt() : null;
      // Rentang target hanya berlaku untuk juz "surah utuh" (29 & 30).
      if (j != null && s != null && QuizJuz.supportsCustomRange(j)) {
        rangeStart[j] = QuizJuz.clampStart(j, s);
      }
    });
    return QuizSettings(
      mode: QuizModeX.fromKey(json['mode'] as String?),
      juz: juz.isEmpty ? const {29, 30} : juz,
      rangeStart: rangeStart,
    );
  }

  @override
  List<Object?> get props => [mode, juz, rangeStart];
}
