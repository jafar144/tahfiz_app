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

  /// Mode PILIHAN: total durasi satu sesi (detik) — hitung mundur time-attack.
  static const int choiceDurationSeconds = 60;

  /// Mode PILIHAN: tambahan waktu (detik) tiap jawaban benar (agar makin seru).
  static const int choiceTimeBonusSeconds = 4;

  /// Mode PILIHAN: jeda tampil umpan balik benar/salah sebelum auto-lanjut.
  static const Duration choiceFeedbackDelay = Duration(milliseconds: 700);

  /// Interval perpanjang "lock" sesi ke server. Harus lebih pendek dari lease
  /// server (2 menit) agar sesi tak dianggap kedaluwarsa saat masih bermain.
  static const Duration heartbeatInterval = Duration(seconds: 40);

  // ════════════════════════════════════════════════════════════════ Poin ════

  /// Mode PILIHAN: poin bila BENAR PENUH, menurut jumlah ayat (all-or-nothing;
  /// salah = 0). Makin banyak ayat, makin besar poinnya.
  static const int choicePoints1Ayah = 10;
  static const int choicePoints2Ayah = 15;
  static const int choicePoints3Ayah = 20;

  /// Poin mode PILIHAN untuk soal berjumlah [ayahCount] ayat.
  static int choicePointsFor(int ayahCount) => switch (ayahCount) {
        3 => choicePoints3Ayah,
        2 => choicePoints2Ayah,
        _ => choicePoints1Ayah,
      };

  /// Soal BONUS (mode suara): poin maksimum satu soal bonus. Poin menyusut
  /// sesuai sisa waktu (jawab lebih cepat → lebih besar); benar tapi mepet tetap
  /// dapat minimal 1.
  static const int bonusMaxPoints = 10;

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
