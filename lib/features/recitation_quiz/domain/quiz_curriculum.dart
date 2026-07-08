import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';

/// Kurikulum Tantangan (mode Challenge) — SATU tempat untuk memetakan kelas
/// santri → cakupan soal kuis.
///
/// ══════════════════════════════════════════════════════════════════════════
/// CARA UPDATE KURIKULUM (bila kurikulum pondok berubah):
///  1. Ubah peta [_scopes] di bawah: tiap kelas berisi daftar `juz` penuh
///     dan/atau `extraSurahs` (id surah mushaf) untuk paket surah pilihan
///     yang TIDAK berurutan (mis. paket Pra Takhossus Awal).
///  2. Cakupan bersifat KUMULATIF — tulis langsung seluruh cakupan kelas itu
///     (termasuk materi kelas di bawahnya), bukan hanya materi barunya.
///  3. Bila soal untuk juz baru sudah tersedia (data ayat di [QuizJuz]),
///     tambahkan nomor juznya ke kelas Takhossus terkait.
///  4. Opsi "turun 1 kelas" diatur di [classBelow]; kembalikan `null` bila
///     kelas itu tidak boleh turun (mis. cakupan kelas bawah sama saja).
/// ══════════════════════════════════════════════════════════════════════════
///
/// Kelas Tahsin (Iqro') TIDAK ikut Tantangan/leaderboard karena materi mereka
/// bukan hafalan Al-Qur'an — cukup kembalikan `null` dari [scopeFor].
class QuizCurriculum {
  QuizCurriculum._();

  /// Paket surah Pra Takhossus Awal (½ juz 29, urutan hafalan pondok):
  /// Al-Mursalat, Al-Qiyamah, Al-Muddatstsir, Al-Ma'arij, Al-Haqqah, Al-Qalam.
  static const Set<int> _praTakhossusAwalSurahs = {77, 75, 74, 70, 69, 68};

  /// Cakupan soal Tantangan per kelas (KUMULATIF — kelas atas otomatis
  /// memuat materi kelas bawahnya).
  ///
  /// Catatan Takhossus: kurikulum aslinya Juz 1–30, tapi soal kuis baru
  /// tersedia untuk Juz 1–3 (plus 29–30 warisan kelas bawah). Bila bank soal
  /// juz lain sudah siap, tambahkan nomor juznya di sini.
  static const Map<String, ChallengeScope> _scopes = {
    'Mutawassith': ChallengeScope(juz: [30]),
    'Pra Takhossus Awal': ChallengeScope(
      juz: [30],
      extraSurahs: _praTakhossusAwalSurahs,
    ),
    'Pra Takhossus Akhir': ChallengeScope(juz: [29, 30]),
    'Takhossus Awal': ChallengeScope(juz: [1, 2, 3, 29, 30]),
    'Takhossus Tsani': ChallengeScope(juz: [1, 2, 3, 29, 30]),
    'Takhossus Tsalits': ChallengeScope(juz: [1, 2, 3, 29, 30]),
    'Takhossus Robi': ChallengeScope(juz: [1, 2, 3, 29, 30]),
    'Takhossus Khomis': ChallengeScope(juz: [1, 2, 3, 29, 30]),
    'Takhossus Akhir': ChallengeScope(juz: [1, 2, 3, 29, 30]),
  };

  /// Cakupan soal untuk [kelas]; `null` bila kelas tidak punya paket Tantangan
  /// (kelas Tahsin / kelas tak dikenal).
  static ChallengeScope? scopeFor(String? kelas) =>
      kelas == null ? null : _scopes[kelas.trim()];

  /// True bila santri kelas ini boleh ikut Tantangan (dan tampil di papan
  /// juara).
  static bool canChallenge(String? kelas) => scopeFor(kelas) != null;

  /// Kelas "1 tingkat di bawah" yang boleh dipilih sebagai cakupan Tantangan
  /// alternatif (untuk santri yang materinya belum tuntas). `null` bila tidak
  /// ada opsi turun:
  ///  • Mutawassith — kelas terbawah yang boleh Tantangan.
  ///  • Takhossus Tsani ke atas — cakupan kelas bawahnya sama persis.
  static String? classBelow(String? kelas) {
    switch (kelas?.trim()) {
      case 'Pra Takhossus Awal':
        return 'Mutawassith';
      case 'Pra Takhossus Akhir':
        return 'Pra Takhossus Awal';
      case 'Takhossus Awal':
        return 'Pra Takhossus Akhir';
      default:
        return null;
    }
  }

  /// Kelas yang tampil di papan juara (urut sesuai jenjang di
  /// [AppConstants.santriClasses]; kelas Tahsin dikecualikan).
  static List<String> get rankableClasses => [
    for (final k in AppConstants.santriClasses)
      if (_scopes.containsKey(k)) k,
  ];

  /// Susun [QuizSettings] Tantangan untuk cakupan [kelas] + [mode]. Rentang
  /// tiap juz selalu penuh (tanpa kustomisasi rentang seperti di Latihan).
  static QuizSettings settingsFor(String kelas, QuizMode mode) {
    final scope = _scopes[kelas.trim()];
    if (scope == null) {
      throw ArgumentError('Kelas "$kelas" tidak punya paket Tantangan.');
    }
    return QuizSettings(
      mode: mode,
      juz: scope.juz.toSet(),
      extraSurahs: scope.extraSurahs,
    );
  }
}

/// Cakupan soal Tantangan sebuah kelas: gabungan juz penuh + surah pilihan.
class ChallengeScope {
  /// Juz yang diikutkan UTUH (harus juz yang didukung [QuizJuz]).
  final List<int> juz;

  /// Surah tambahan di luar [juz] (id mushaf) — untuk paket surah pilihan
  /// yang tidak berurutan. Surah berurutan otomatis dirangkai sebagai satu
  /// segmen sambungan ayat.
  final Set<int> extraSurahs;

  const ChallengeScope({required this.juz, this.extraSurahs = const {}});
}
