import 'dart:math';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';

/// Jenis soal bonus (mode suara) yang muncul setelah bacaan lolos.
enum QuizBonusType {
  /// "Ayat tadi dari surah apa?" — identifikasi surah passage (bisa 2 surah).
  identify,

  /// "Surah apa yang N surah sebelum/sesudah surah X?" — uji urutan surah.
  neighbor,
}

/// Soal bonus tebak surah: pilihan ganda nama surah, ada hitung mundur.
///
/// Semua surah jawaban dijamin berada dalam rentang target yang dipilih santri
/// (tidak "overflow" keluar juz/rentang).
class QuizBonusQuestion {
  final QuizBonusType type;

  /// Surah id jawaban benar, urut mushaf. Panjang 1 (umum) atau 2 (identify
  /// bila passage melintasi 2 surah → jawaban jadi multi-pilih).
  final List<int> answerSurahs;

  /// Opsi surah id (teracak) — memuat [answerSurahs] + distraktor.
  final List<int> options;

  /// Untuk [neighbor]: surah acuan yang ditampilkan pada pertanyaan.
  final int referenceSurah;

  /// Untuk [neighbor]: jarak surah (1..3).
  final int offset;

  /// Untuk [neighbor]: true = sesudah, false = sebelum.
  final bool after;

  const QuizBonusQuestion({
    required this.type,
    required this.answerSurahs,
    required this.options,
    this.referenceSurah = 0,
    this.offset = 0,
    this.after = true,
  });

  /// Jawaban lebih dari satu surah (identify multi).
  bool get isMulti => answerSurahs.length > 1;

  /// Jumlah opsi yang harus dipilih.
  int get requiredPicks => answerSurahs.length;

  /// Indeks opsi benar, TERURUT sesuai [answerSurahs].
  List<int> get correctOptionOrder =>
      answerSurahs.map(options.indexOf).toList();

  /// Nama surah untuk sebuah opsi.
  String optionName(int optionIndex) => QuizJuz.nameOf(options[optionIndex]);

  /// Nama surah jawaban benar (urut), untuk ditampilkan saat salah/waktu habis.
  List<String> get answerNames =>
      answerSurahs.map(QuizJuz.nameOf).toList(growable: false);

  /// Teks pertanyaan siap tampil. Untuk [neighbor], surah acuan SENGAJA tidak
  /// disebut namanya — santri harus mengenali sendiri surah dari ayat tadi.
  String get questionText {
    if (type == QuizBonusType.neighbor) {
      final dir = after ? 'setelah' : 'sebelum';
      return '$offset surah $dir surah dari ayat tadi, surahnya apa?';
    }
    return isMulti
        ? 'Ayat tadi mencakup surah apa saja?'
        : 'Ayat tadi dari surah apa?';
  }

  /// Detik hitung mundur untuk soal ini: identify pakai durasi dasar; neighbor
  /// diberi waktu ekstra sesuai jarak surah. (Lihat [QuizConfig.bonusBaseSeconds]
  /// & [QuizConfig.bonusPerOffsetExtraSeconds].)
  int get durationSeconds => type == QuizBonusType.neighbor
      ? QuizConfig.bonusBaseSeconds +
          (offset - 1) * QuizConfig.bonusPerOffsetExtraSeconds
      : QuizConfig.bonusBaseSeconds;

  /// Susun soal bonus dari soal suara [q] yang lolos & himpunan surah dalam
  /// rentang target [allowed]. Kembalikan null bila tak bisa disusun.
  static QuizBonusQuestion? generate({
    required QuizQuestion q,
    required Set<int> allowed,
    required Random rng,
  }) {
    // Surah yang tercakup JAWABAN (yang santri baca), urut mushaf. Surah ayat
    // soal (prompt) sengaja TIDAK diikutkan — fokus tebakan adalah surah yang
    // dibaca, bukan surah petunjuk. Multi-pilih hanya bila jawaban sendiri
    // benar-benar melintasi ≥2 surah.
    final readSurahs = <int>{...q.answerAyat.map((a) => a.surahId)}.toList()
      ..sort();

    // Semua surah bernama (juz 29 & 30) sebagai cadangan distraktor.
    final named = QuizJuz.surahLatin.keys.toSet();

    // Jawaban melintasi ≥2 surah → identify multi (tanpa neighbor).
    if (readSurahs.length >= 2) {
      return _identify(readSurahs, allowed, named, rng);
    }

    final base = readSurahs.first;

    // Kandidat neighbor yang targetnya masih dalam rentang (tidak overflow).
    final candidates = <({int off, bool after})>[];
    for (var off = 1; off <= 3; off++) {
      for (final after in const [true, false]) {
        final target = after ? base + off : base - off;
        if (allowed.contains(target) && named.contains(target)) {
          candidates.add((off: off, after: after));
        }
      }
    }

    // Acak antara neighbor (bila ada) & identify tunggal.
    if (candidates.isNotEmpty && rng.nextBool()) {
      final c = candidates[rng.nextInt(candidates.length)];
      final target = c.after ? base + c.off : base - c.off;
      final options = _assembleOptions(
        answers: [target],
        preferred: allowed,
        fallback: named,
        rng: rng,
        exclude: base,
      );
      if (options != null) {
        return QuizBonusQuestion(
          type: QuizBonusType.neighbor,
          answerSurahs: [target],
          options: options,
          referenceSurah: base,
          offset: c.off,
          after: c.after,
        );
      }
    }
    return _identify([base], allowed, named, rng);
  }

  static QuizBonusQuestion? _identify(
    List<int> answers,
    Set<int> preferred,
    Set<int> fallback,
    Random rng,
  ) {
    final options = _assembleOptions(
      answers: answers,
      preferred: preferred,
      fallback: fallback,
      rng: rng,
    );
    if (options == null) return null;
    return QuizBonusQuestion(
      type: QuizBonusType.identify,
      answerSurahs: answers,
      options: options,
    );
  }

  /// Rakit [QuizConfig.bonusOptionCount] opsi: jawaban + distraktor unik (utamakan [preferred]
  /// = surah dalam rentang, lalu [fallback]), teracak. Null bila distraktor tak
  /// cukup untuk satu opsi salah pun.
  static List<int>? _assembleOptions({
    required List<int> answers,
    required Set<int> preferred,
    required Set<int> fallback,
    required Random rng,
    int exclude = 0,
  }) {
    final chosen = <int>{...answers};

    List<int> pickable(Set<int> from) => from
        .where((s) =>
            s != exclude &&
            !chosen.contains(s) &&
            QuizJuz.surahLatin.containsKey(s))
        .toList()
      ..shuffle(rng);

    for (final s in pickable(preferred)) {
      if (chosen.length >= QuizConfig.bonusOptionCount) break;
      chosen.add(s);
    }
    if (chosen.length < QuizConfig.bonusOptionCount) {
      for (final s in pickable(fallback)) {
        if (chosen.length >= QuizConfig.bonusOptionCount) break;
        chosen.add(s);
      }
    }
    if (chosen.length < answers.length + 1) return null;
    return chosen.toList()..shuffle(rng);
  }
}
