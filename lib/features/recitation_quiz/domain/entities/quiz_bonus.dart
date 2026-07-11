import 'dart:math';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_surah_facts.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';

/// Jenis soal bonus (mode suara) / trivia surah (mode pilihan).
enum QuizBonusType {
  /// "Ayat tadi dari surah apa?" — identifikasi surah passage (bisa 2 surah).
  identify,

  /// "Surah apa yang N surah sebelum/sesudah surah X?" — uji urutan surah.
  neighbor,

  /// "Apa nama DAN arti surah tersebut?" — dua bagian jawaban; benar satu
  /// bagian → setengah poin.
  nameMeaning,

  /// "Jika surah X urutan ke-X, surah tersebut urutan ke berapa?" — tebak
  /// nomor urut mushaf dengan surah acuan berjarak maks ±5.
  orderNumber,

  /// "Berapa jumlah ayat surah tersebut?"
  ayahCount,
}

/// Tingkat kesulitan soal bonus (mode suara) — menentukan poin penuh & durasi.
enum QuizBonusDifficulty { easy, medium, hard }

/// Soal bonus / trivia surah: pilihan ganda seputar surah, ada hitung mundur
/// pada mode suara.
///
/// Semua surah jawaban dijamin berada dalam rentang target yang dipilih santri
/// (tidak "overflow" keluar juz/rentang).
class QuizBonusQuestion {
  final QuizBonusType type;

  /// Surah id jawaban benar, urut mushaf. Panjang 1 (umum) atau 2 (identify
  /// bila passage melintasi 2 surah → jawaban jadi multi-pilih).
  final List<int> answerSurahs;

  /// Opsi surah id (teracak) — memuat [answerSurahs] + distraktor. Untuk
  /// [QuizBonusType.nameMeaning] ini opsi bagian NAMA; kosong pada soal angka.
  final List<int> options;

  /// Opsi ARTI surah (teracak, unik per teks) — hanya [nameMeaning].
  final List<String> meaningOptions;

  /// Opsi ANGKA (teracak) — hanya [orderNumber] (nomor urut) & [ayahCount]
  /// (jumlah ayat). Memuat [answerNumber].
  final List<int> numberOptions;

  /// Untuk [neighbor] & [orderNumber]: surah acuan yang disebut di pertanyaan.
  final int referenceSurah;

  /// Untuk [neighbor]: jarak surah (1..3).
  final int offset;

  /// Untuk [neighbor]: true = sesudah, false = sebelum.
  final bool after;
  final VocabMatchQuestion? vocabMatch;

  const QuizBonusQuestion({
    required this.type,
    required this.answerSurahs,
    required this.options,
    this.meaningOptions = const [],
    this.numberOptions = const [],
    this.referenceSurah = 0,
    this.offset = 0,
    this.after = true,
    this.vocabMatch,
  });

  const QuizBonusQuestion.vocabularyMatch(VocabMatchQuestion match)
    : type = QuizBonusType.identify,
      answerSurahs = const [],
      options = const [],
      meaningOptions = const [],
      numberOptions = const [],
      referenceSurah = 0,
      offset = 0,
      after = true,
      vocabMatch = match;

  bool get isVocabMatch => vocabMatch != null;

  /// Jawaban lebih dari satu surah (identify multi).
  bool get isMulti => answerSurahs.length > 1;

  bool get isNameMeaning => type == QuizBonusType.nameMeaning;

  /// Soal berjawaban angka (urutan surah / jumlah ayat).
  bool get isNumber =>
      type == QuizBonusType.orderNumber || type == QuizBonusType.ayahCount;

  /// Butuh tombol "Jawab" (tak auto-nilai saat satu opsi diketuk): identify
  /// multi & nama+arti (dua bagian).
  bool get needsSubmit => isMulti || isNameMeaning;

  /// Jumlah opsi (bagian nama/surah) yang harus dipilih.
  int get requiredPicks => answerSurahs.length;

  /// Indeks opsi benar, TERURUT sesuai [answerSurahs].
  List<int> get correctOptionOrder =>
      answerSurahs.map(options.indexOf).toList();

  /// Nama surah untuk sebuah opsi.
  String optionName(int optionIndex) => QuizJuz.nameOf(options[optionIndex]);

  /// Nama surah jawaban benar (urut), untuk ditampilkan saat salah/waktu habis.
  List<String> get answerNames =>
      answerSurahs.map(QuizJuz.nameOf).toList(growable: false);

  /// Arti surah jawaban ([nameMeaning]).
  String get answerMeaning => QuizSurahFacts.meaningOf(answerSurahs.first);

  /// Jawaban angka: [orderNumber] → id surah (id mushaf = nomor urut);
  /// [ayahCount] → jumlah ayat surah.
  int get answerNumber => type == QuizBonusType.orderNumber
      ? answerSurahs.first
      : QuizSurahFacts.ayahCountOf(answerSurahs.first);

  /// True bila pilihan bagian NAMA benar ([nameMeaning]).
  bool nameCorrect(int? pick) =>
      pick != null &&
      pick >= 0 &&
      pick < options.length &&
      options[pick] == answerSurahs.first;

  /// True bila pilihan bagian ARTI benar ([nameMeaning]).
  bool meaningCorrect(int? pick) =>
      pick != null &&
      pick >= 0 &&
      pick < meaningOptions.length &&
      meaningOptions[pick] == answerMeaning;

  /// True bila pilihan angka benar ([orderNumber]/[ayahCount]).
  bool numberCorrect(int? pick) =>
      pick != null &&
      pick >= 0 &&
      pick < numberOptions.length &&
      numberOptions[pick] == answerNumber;

  /// Tingkat kesulitan soal bonus (mode suara) → menentukan poin penuh &
  /// durasi hitung mundur.
  QuizBonusDifficulty get difficulty => switch (type) {
    QuizBonusType.identify => QuizBonusDifficulty.easy,
    QuizBonusType.ayahCount => QuizBonusDifficulty.medium,
    QuizBonusType.nameMeaning => QuizBonusDifficulty.medium,
    QuizBonusType.neighbor => QuizBonusDifficulty.hard,
    QuizBonusType.orderNumber => QuizBonusDifficulty.hard,
  };

  /// Poin PENUH bila benar (mode suara), nilai tetap. Untuk [nameMeaning],
  /// benar satu bagian saja → setengah dari nilai ini.
  int get fullPoints => QuizConfig.bonusPointsVoice;

  /// Teks jawaban benar siap tampil (saat salah/waktu habis).
  String get answerLabel => switch (type) {
    _ when isVocabMatch => 'Kosa kata selesai dicocokkan',
    QuizBonusType.nameMeaning =>
      '${QuizJuz.nameOf(answerSurahs.first)} — $answerMeaning',
    QuizBonusType.orderNumber =>
      'Urutan ke-${answerSurahs.first} (${QuizJuz.nameOf(answerSurahs.first)})',
    QuizBonusType.ayahCount =>
      '$answerNumber ayat (${QuizJuz.nameOf(answerSurahs.first)})',
    _ => answerNames.join(', '),
  };

  /// Teks pertanyaan dengan [subject] = frasa ayat rujukan ("ayat tadi" di
  /// bonus suara, "ayat di atas" di mode pilihan). Untuk [neighbor] &
  /// [orderNumber], surah target SENGAJA tidak disebut namanya — santri harus
  /// mengenali sendiri surahnya dari ayat.
  String questionTextWith(String subject) => switch (type) {
    _ when isVocabMatch => 'Cocokkan kosa kata Arab dengan artinya',
    QuizBonusType.neighbor =>
      '$offset surah ${after ? 'setelah' : 'sebelum'} surah dari '
          '$subject, surahnya apa?',
    QuizBonusType.nameMeaning => 'Apa NAMA dan ARTI surah dari $subject?',
    QuizBonusType.orderNumber =>
      'Surah dari $subject urutan ke berapa dalam Al-Qur\'an?',
    QuizBonusType.ayahCount => 'Berapa jumlah ayat surah dari $subject?',
    QuizBonusType.identify =>
      isMulti
          ? '${_cap(subject)} mencakup surah apa saja?'
          : '${_cap(subject)} dari surah apa?',
  };

  /// Petunjuk tambahan yang ditampilkan di bawah pertanyaan. Untuk [orderNumber]
  /// menyebut satu surah acuan + nomornya sebagai titik hitung; null untuk tipe
  /// lain.
  String? get hintText => type == QuizBonusType.orderNumber
      ? '${QuizJuz.nameOf(referenceSurah)} = surah ke-$referenceSurah'
      : null;

  /// Teks pertanyaan untuk bonus mode suara (merujuk bacaan barusan).
  String get questionText => questionTextWith('ayat tadi');

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Detik hitung mundur untuk soal ini (bonus mode suara) menurut [difficulty]
  /// — makin sulit, makin lama waktunya.
  int get durationSeconds => switch (difficulty) {
    QuizBonusDifficulty.easy => QuizConfig.bonusSecondsEasy,
    QuizBonusDifficulty.medium => QuizConfig.bonusSecondsMedium,
    QuizBonusDifficulty.hard => QuizConfig.bonusSecondsHard,
  };

  /// Susun soal bonus (mode suara) dari surah-surah yang BARUSAN DIBACA santri
  /// [readSurahs] & himpunan surah dalam rentang target [allowed]. Jenis soal
  /// diundi rata dari semua tipe yang bisa disusun. Null bila tak ada satu pun.
  static QuizBonusQuestion? generate({
    required List<int> readSurahs,
    required Set<int> allowed,
    required Random rng,
  }) {
    // Surah yang tercakup jawaban (yang santri baca), urut mushaf. Multi-pilih
    // hanya bila bacaan benar-benar melintasi ≥2 surah.
    final surahs = <int>{...readSurahs}.toList()..sort();

    // Semua surah bernama (juz 29 & 30) sebagai cadangan distraktor.
    final named = QuizJuz.surahLatin.keys.toSet();

    // Bacaan melintasi ≥2 surah → identify multi (tipe lain tak relevan).
    if (surahs.length >= 2) {
      return _identify(surahs, allowed, named, rng);
    }

    final base = surahs.first;

    // Kumpulkan semua tipe yang mungkin, undi rata, pakai yang pertama sukses.
    final builders = <QuizBonusQuestion? Function()>[
      () => _identify([base], allowed, named, rng),
      if (_neighborCandidates(base, allowed, named).isNotEmpty)
        () => _neighbor(base, allowed, named, rng),
      if (QuizSurahFacts.has(base) && named.contains(base)) ...[
        () => _nameMeaning(base, allowed, named, rng),
        () => _ayahCount(base, rng),
        if (_orderReferenceCandidates(base, named).isNotEmpty)
          () => _orderNumber(base, named, rng),
      ],
    ]..shuffle(rng);

    for (final build in builders) {
      final q = build();
      if (q != null) return q;
    }
    return null;
  }

  /// Susun soal TRIVIA surah [surah] untuk mode PILIHAN (nama+arti / urutan /
  /// jumlah ayat — tanpa identify/neighbor). Bila [type] diberikan, hanya tipe
  /// itu yang disusun (agar penyusun bisa merotasi tipe secara merata); null
  /// bila tipe itu tak bisa disusun untuk surah ini. Bila [type] null, tipe
  /// diundi rata. Null bila data surah tak lengkap.
  static QuizBonusQuestion? generateTrivia({
    required int surah,
    required Set<int> allowed,
    required Random rng,
    QuizBonusType? type,
  }) {
    final named = QuizJuz.surahLatin.keys.toSet();
    if (!QuizSurahFacts.has(surah) || !named.contains(surah)) return null;

    QuizBonusQuestion? build(QuizBonusType t) => switch (t) {
      QuizBonusType.nameMeaning => _nameMeaning(surah, allowed, named, rng),
      QuizBonusType.ayahCount => _ayahCount(surah, rng),
      QuizBonusType.orderNumber =>
        _orderReferenceCandidates(surah, named).isEmpty
            ? null
            : _orderNumber(surah, named, rng),
      _ => null,
    };

    if (type != null) return build(type);

    final types = [
      QuizBonusType.nameMeaning,
      QuizBonusType.ayahCount,
      QuizBonusType.orderNumber,
    ]..shuffle(rng);
    for (final t in types) {
      final q = build(t);
      if (q != null) return q;
    }
    return null;
  }

  // ── Penyusun per tipe ────────────────────────────────────────────────────

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

  /// Kandidat neighbor yang targetnya masih dalam rentang (tidak overflow).
  static List<({int off, bool after})> _neighborCandidates(
    int base,
    Set<int> allowed,
    Set<int> named,
  ) {
    final candidates = <({int off, bool after})>[];
    for (var off = 1; off <= 3; off++) {
      for (final after in const [true, false]) {
        final target = after ? base + off : base - off;
        if (allowed.contains(target) && named.contains(target)) {
          candidates.add((off: off, after: after));
        }
      }
    }
    return candidates;
  }

  static QuizBonusQuestion? _neighbor(
    int base,
    Set<int> allowed,
    Set<int> named,
    Random rng,
  ) {
    final candidates = _neighborCandidates(base, allowed, named);
    if (candidates.isEmpty) return null;
    final c = candidates[rng.nextInt(candidates.length)];
    final target = c.after ? base + c.off : base - c.off;
    final options = _assembleOptions(
      answers: [target],
      preferred: allowed,
      fallback: named,
      rng: rng,
      exclude: base,
    );
    if (options == null) return null;
    return QuizBonusQuestion(
      type: QuizBonusType.neighbor,
      answerSurahs: [target],
      options: options,
      referenceSurah: base,
      offset: c.off,
      after: c.after,
    );
  }

  static QuizBonusQuestion? _nameMeaning(
    int base,
    Set<int> preferred,
    Set<int> fallback,
    Random rng,
  ) {
    final options = _assembleOptions(
      answers: [base],
      preferred: preferred,
      fallback: fallback,
      rng: rng,
    );
    if (options == null) return null;
    final meanings = _assembleMeaningOptions(base, preferred, fallback, rng);
    if (meanings == null) return null;
    return QuizBonusQuestion(
      type: QuizBonusType.nameMeaning,
      answerSurahs: [base],
      options: options,
      meaningOptions: meanings,
    );
  }

  static QuizBonusQuestion? _ayahCount(int base, Random rng) {
    final count = QuizSurahFacts.ayahCountOf(base);
    if (count <= 0) return null;
    return QuizBonusQuestion(
      type: QuizBonusType.ayahCount,
      answerSurahs: [base],
      options: const [],
      // Surah terpendek Al-Qur'an 3 ayat → tak ada opsi di bawah itu.
      numberOptions: _assembleNumberOptions(
        answer: count,
        min: 3,
        max: 300,
        rng: rng,
      ),
    );
  }

  /// Kandidat surah acuan untuk [orderNumber]: bernama & berjarak
  /// 1..[QuizConfig.orderNumberMaxRefDistance] dari target (tidak jauh-jauh).
  static List<int> _orderReferenceCandidates(int base, Set<int> named) => [
    for (var d = 1; d <= QuizConfig.orderNumberMaxRefDistance; d++)
      for (final r in [base - d, base + d])
        if (named.contains(r)) r,
  ];

  static QuizBonusQuestion? _orderNumber(int base, Set<int> named, Random rng) {
    final refs = _orderReferenceCandidates(base, named);
    if (refs.isEmpty) return null;
    final ref = refs[rng.nextInt(refs.length)];
    return QuizBonusQuestion(
      type: QuizBonusType.orderNumber,
      answerSurahs: [base],
      options: const [],
      // Nomor acuan dikecualikan dari opsi (jelas bukan jawaban).
      numberOptions: _assembleNumberOptions(
        answer: base,
        exclude: {ref},
        min: 1,
        max: 114,
        rng: rng,
      ),
      referenceSurah: ref,
    );
  }

  // ── Perakit opsi ─────────────────────────────────────────────────────────

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

    List<int> pickable(Set<int> from) =>
        from
            .where(
              (s) =>
                  s != exclude &&
                  !chosen.contains(s) &&
                  QuizJuz.surahLatin.containsKey(s),
            )
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

  /// Rakit opsi ARTI surah: arti jawaban + arti surah lain sebagai distraktor,
  /// unik per TEKS (beberapa surah punya arti sama persis — di-dedup agar tak
  /// ada opsi kembar). Null bila tak ada satu pun distraktor.
  static List<String>? _assembleMeaningOptions(
    int base,
    Set<int> preferred,
    Set<int> fallback,
    Random rng,
  ) {
    // LinkedHashSet menjaga keunikan teks sekaligus urutan penambahan.
    final chosen = <String>{QuizSurahFacts.meaningOf(base)};

    List<int> pickable(Set<int> from) =>
        from.where((s) => s != base && QuizSurahFacts.has(s)).toList()
          ..shuffle(rng);

    for (final s in pickable(preferred)) {
      if (chosen.length >= QuizConfig.bonusOptionCount) break;
      chosen.add(QuizSurahFacts.meaningOf(s));
    }
    if (chosen.length < QuizConfig.bonusOptionCount) {
      for (final s in pickable(fallback)) {
        if (chosen.length >= QuizConfig.bonusOptionCount) break;
        chosen.add(QuizSurahFacts.meaningOf(s));
      }
    }
    if (chosen.length < 2) return null;
    return chosen.toList()..shuffle(rng);
  }

  /// Rakit opsi ANGKA: jawaban + angka unik di sekitarnya (jendela melebar
  /// bila kandidat kurang), dibatasi [min]..[max], teracak.
  static List<int> _assembleNumberOptions({
    required int answer,
    required Random rng,
    Set<int> exclude = const {},
    int min = 1,
    int max = 999,
  }) {
    final chosen = <int>{answer};
    var radius = QuizConfig.orderNumberMaxRefDistance;
    while (chosen.length < QuizConfig.bonusOptionCount && radius < 60) {
      final candidates = [
        for (var n = answer - radius; n <= answer + radius; n++)
          if (n >= min &&
              n <= max &&
              !exclude.contains(n) &&
              !chosen.contains(n))
            n,
      ]..shuffle(rng);
      for (final n in candidates) {
        if (chosen.length >= QuizConfig.bonusOptionCount) break;
        chosen.add(n);
      }
      radius += 5;
    }
    return chosen.toList()..shuffle(rng);
  }
}
