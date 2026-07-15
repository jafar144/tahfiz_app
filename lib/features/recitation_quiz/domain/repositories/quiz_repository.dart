import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_tier.dart';

abstract class QuizRepository {
  /// Susun [count] soal acak sesuai [settings] (juz terpilih + sambungan antar
  /// surah). Tiap soal: 1 ayat petunjuk + tugas yang bervariasi.
  ///
  /// Mode suara: lanjutkan 1-4 ayat, baca ayat terakhir, baca ayat ke-N, atau
  /// tebak dan baca ayat dari makna kosakata (lihat [QuizVoiceTask]).
  ///
  /// Mode pilihan (`settings.mode == choice`): tiap soal memuat `options`
  /// (6 ayat teracak berisi jawaban benar), diselingi soal TRIVIA surah
  /// Soal inti dan cadangan bonus dibentuk sesuai rules tiap mode dan profil
  /// kesulitan di [QuizSettings].
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count,
    required QuizSettings settings,
  });

  /// Transkripsi audio lalu cocokkan dengan ayat jawaban.
  Future<Either<Failure, RecitationResult>> checkAnswer({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  });

  /// Simpan hasil sesi TANTANGAN (khusus santri; admin & asatidz dilewati).
  /// Ditulis ke koleksi histori; leaderboard [mode] hanya diperbarui bila
  /// [score] melebihi best-score user bulan ini. Sesi LATIHAN tidak disimpan
  /// (cubit tidak memanggil ini).
  ///
  /// [score] = skor leaderboard (suara: rata-rata 0..100 + bonus; pilihan:
  /// total poin + bonus). [bonusTotal] = total poin bonus terpisah.
  /// Skor terbaik dipisah berdasarkan [tier]; satu santri dapat tercatat pada
  /// beberapa tingkatan dalam bulan yang sama.
  Future<Either<Failure, void>> saveAttempt({
    required QuizMode mode,
    QuizDifficulty difficulty = QuizDifficulty.easy,
    required int score,
    required List<int> questionScores,
    required List<int> juz,
    int bonusTotal = 0,
    int earnedXp = 0,
    required String studentClass,
    required String scopeClass,
    required QuizTier tier,
  });

  /// Tambahkan XP kuis ke progres Arena/Journey pengguna saat sesi selesai.
  /// Best-effort; berlaku untuk semua role agar sesi latihan tetap menaikkan XP.
  Future<Either<Failure, void>> awardXp(int amount);

  /// Papan juara [mode] bulan berjalan: top-10 skor tertinggi per user
  /// + peringkat user saat ini, dipisah per [tierKey].
  Future<Either<Failure, MonthlyLeaderboard>> getMonthlyLeaderboard(
    QuizMode mode, {
    required String tierKey,
  });

  /// True bila user saat ini ber-role `admin`. Dipakai untuk melewati sistem
  /// energi/lock (admin bisa menguji kuis tanpa batas). Best-effort: bila
  /// gagal membaca profil, dianggap non-admin (energi tetap berlaku).
  Future<bool> isCurrentUserAdmin();

  /// Energi kuis terkini (sudah memperhitungkan pengisian otomatis).
  Future<Either<Failure, QuizEnergy>> getEnergy();

  /// Mulai sesi (server-side): latihan → potong 1 energi; Tantangan → cek &
  /// tandai jatah harian (1x/hari per mode). Mode suara juga mengambil lock
  /// 1-user (jaga kuota Whisper). Left berisi [QuizBlockedFailure] bila
  /// terblokir (sibuk / kuota / energi / jatah harian).
  Future<Either<Failure, QuizEnergy>> startSession({
    required QuizMode mode,
    bool challenge = false,
  });

  /// Perpanjang lock selama bermain (best-effort, diabaikan bila gagal).
  Future<void> heartbeat();

  /// Lepas lock saat sesi selesai / keluar (best-effort).
  Future<void> endSession();
}
