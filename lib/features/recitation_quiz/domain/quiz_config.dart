/// Konfigurasi & konstanta gameplay Kuis Hafalan — SATU tempat untuk semua
/// angka yang bisa disetel: durasi timer, jumlah soal, poin, ambang lolos, dsb.
///
/// Ubah nilai di sini untuk menyetel keseimbangan permainan; logika di file lain
/// (cubit, entity, repository) sudah mengambil dari sini, jadi tak perlu diubah.
class QuizConfig {
  QuizConfig._();

  // ══════════════════════════════════════════════════════ Jumlah soal ══════

  /// Mode SUARA: jumlah soal per sesi.
  static const int voiceQuestionCount = 10;

  /// Mode PILIHAN: jumlah soal yang disiapkan. Sengaja berlebih karena sesi
  /// dibatasi WAKTU (bukan jumlah soal) — pool besar agar tak habis lebih dulu.
  static const int choicePoolCount = 40;

  /// Mode PILIHAN: jumlah opsi ayat per soal (memuat jawaban benar + distraktor).
  static const int choiceOptionCount = 6;

  /// Soal BONUS "tebak surah": jumlah opsi nama surah (jawaban + distraktor).
  static const int bonusOptionCount = 6;

  /// Maksimum ayat yang harus dilanjutkan dalam satu soal (jawaban 1..maks ayat).
  static const int maxAnswerAyah = 3;

  /// Soal suara "baca ayat ke-N": N diundi 1..min(nilai ini, jumlah ayat surah).
  static const int specificAyahMaxNumber = 5;

  /// Bobot undian tipe soal INTI mode suara (relatif): lanjutkan ayat tetap
  /// jadi menu utama, dua variasi baru berbagi sisanya.
  static const int voiceTaskWeightContinue = 2;
  static const int voiceTaskWeightLastAyah = 1;
  static const int voiceTaskWeightSpecificAyah = 1;

  /// Mode PILIHAN: tiap KELIPATAN nilai ini, soal yang muncul adalah soal
  /// TRIVIA/BONUS surah (nama+arti / urutan / jumlah ayat) — punya timer
  /// sendiri; selebihnya soal lanjutan ayat biasa.
  static const int choiceTriviaInterval = 5;

  /// Jumlah entri teratas yang ditampilkan pada papan peringkat (leaderboard).
  static const int leaderboardLimit = 10;

  // ═══════════════════════════════════════════════════════════════ Waktu ════

  /// Mode SUARA: batas waktu berpikir + menjawab per soal (detik). Bila habis
  /// sebelum jawaban dikirim → soal di-skip otomatis (Soal Bonus ikut hangus).
  static const int voiceQuestionSeconds = 30;

  /// Mode SUARA: jeda berpikir (detik) setelah lolos, sebelum Soal Bonus mulai
  /// secara otomatis.
  static const int bonusPrepSeconds = 5;

  /// Soal BONUS: hitung mundur dasar (detik) untuk tipe "identify" (tebak surah
  /// ayat tadi).
  static const int bonusBaseSeconds = 15;

  /// Soal BONUS tipe "neighbor" (surah ke-N sebelum/sesudah): tambahan detik per
  /// jarak surah. Durasi = [bonusBaseSeconds] + (jarak − 1) × nilai ini.
  static const int bonusPerOffsetExtraSeconds = 2;

  /// Soal BONUS tipe trivia baru (nama+arti / urutan / jumlah ayat): durasi
  /// hitung mundur = poin tipe soal + nilai ini (poin X → waktu X+3 detik).
  static const int triviaBonusExtraSeconds = 3;

  /// Mode PILIHAN: total durasi satu sesi (detik) — hitung mundur time-attack.
  static const int choiceDurationSeconds = 60;

  /// Mode PILIHAN — Soal BONUS (trivia surah): hitung mundur MILIK SENDIRI.
  /// Selama soal bonus berlangsung, timer sesi utama DIJEDA (seolah waktu
  /// permainan berhenti). Bila terjawab benar penuh: +[choiceTriviaTimeBonus]
  /// detik & +[choiceTriviaPoints] poin ke sesi utama (benar sebagian pada
  /// nama+arti → setengahnya).
  static const int choiceTriviaSeconds = 15;
  static const int choiceTriviaTimeBonus = 10;
  static const int choiceTriviaPoints = 20;

  /// Mode PILIHAN: durasi splash "Soal Bonus" sesaat sebelum soal trivia
  /// muncul (transisi masuk).
  static const Duration choiceTriviaIntro = Duration(milliseconds: 1300);

  /// Mode PILIHAN: durasi memperlihatkan HADIAH Soal Bonus (poin & waktu gratis
  /// beranimasi terbang ke HUD) setelah jawaban benar, sebelum lanjut otomatis.
  static const Duration choiceBonusReward = Duration(milliseconds: 1600);

  /// Mode PILIHAN: jeda tampil umpan balik benar/salah sebelum auto-lanjut.
  static const Duration choiceFeedbackDelay = Duration(milliseconds: 700);

  /// Interval perpanjang "lock" sesi ke server. Harus lebih pendek dari lease
  /// server (2 menit) agar sesi tak dianggap kedaluwarsa saat masih bermain.
  static const Duration heartbeatInterval = Duration(seconds: 40);

  // ════════════════════════════════════════════════════════════════ Poin ════

  /// Mode PILIHAN (soal lanjutan ayat): poin bila BENAR = 4n + 6, dengan
  /// n = jumlah ayat yang diminta. 1 ayat→10, 2→14, 3→18. Salah = 0.
  static int choicePointsFor(int ayahCount) => 4 * ayahCount + 6;

  /// Mode PILIHAN (soal lanjutan ayat): tambahan waktu bila BENAR = n + 1
  /// detik (n = jumlah ayat). 1 ayat→+2 dtk, 2→+3, 3→+4.
  static int choiceTimeBonusFor(int ayahCount) => ayahCount + 1;

  /// Soal BONUS (mode suara): poin maksimum satu soal bonus. Poin menyusut
  /// sesuai sisa waktu (jawab lebih cepat → lebih besar); benar tapi mepet tetap
  /// dapat minimal 1.
  static const int bonusMaxPoints = 10;

  /// Poin soal TRIVIA surah (dipakai penuh di mode PILIHAN; di mode suara,
  /// nilai ini "ditukar" jadi durasi soal bonus = poin + 3 detik).
  /// - nameMeaning : nama + arti surah (benar satu bagian → setengah poin).
  /// - orderNumber : tebak nomor urut surah dari surah acuan (sulit).
  /// - ayahCount   : jumlah ayat surah.
  static const int triviaPointsNameMeaning = 14;
  static const int triviaPointsOrderNumber = 17;
  static const int triviaPointsAyahCount = 12;

  /// Soal trivia "urutan surah": jarak maksimum surah acuan dari surah target
  /// (acuan diundi ±1..nilai ini, tidak boleh jauh-jauh).
  static const int orderNumberMaxRefDistance = 5;

  // ══════════════════════════════════════════════════════════════ Ambang ════

  /// Mode SUARA: ambang persentase akurasi minimal agar bacaan dianggap LOLOS.
  static const int passThreshold = 80;

  /// Mode SUARA: di atas ambang ini, skor soal dibulatkan penuh menjadi 100.
  static const int perfectThreshold = 90;

  // ══════════════════════════════════════════════════════════════ Sistem ════

  /// Saklar sistem energi (master switch). `false` = energi tak pernah dipotong
  /// & lock sesi dilewati (kuis bebas dimainkan; berguna untuk testing).
  /// Kembalikan ke `true` untuk produksi. Catatan: admin selalu melewati ini.
  static const bool enforceEnergy = true;
}
