import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';

abstract class QuizRepository {
  /// Susun [count] soal acak sesuai [settings] (juz terpilih + sambungan antar
  /// surah). Tiap soal: 1 ayat petunjuk → lanjutkan 1-3 ayat berikutnya.
  ///
  /// Pada mode pilihan (`settings.mode == choice`), tiap soal juga memuat
  /// `options` (6 ayat teracak berisi jawaban benar).
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

  /// Simpan hasil sesi kuis (khusus santri; admin & asatidz dilewati). Ditulis
  /// ke koleksi histori; leaderboard [mode] hanya diperbarui bila [score]
  /// melebihi best-score user bulan ini.
  ///
  /// [score] = skor leaderboard (suara: rata-rata 0..100; pilihan: total poin).
  Future<Either<Failure, void>> saveAttempt({
    required QuizMode mode,
    required int score,
    required List<int> questionScores,
    required List<int> juz,
  });

  /// Papan juara [mode] bulan berjalan: top-10 skor tertinggi per user
  /// + peringkat user saat ini. Leaderboard dipisah per mode.
  Future<Either<Failure, MonthlyLeaderboard>> getMonthlyLeaderboard(
    QuizMode mode,
  );

  /// True bila user saat ini ber-role `admin`. Dipakai untuk melewati sistem
  /// energi/lock (admin bisa menguji kuis tanpa batas). Best-effort: bila
  /// gagal membaca profil, dianggap non-admin (energi tetap berlaku).
  Future<bool> isCurrentUserAdmin();

  /// Energi kuis terkini (sudah memperhitungkan pengisian otomatis).
  Future<Either<Failure, QuizEnergy>> getEnergy();

  /// Mulai sesi: ambil lock 1-user + potong 1 energi (server-side).
  /// Left berisi [QuizBlockedFailure] bila terblokir (sibuk / kuota / energi).
  Future<Either<Failure, QuizEnergy>> startSession();

  /// Perpanjang lock selama bermain (best-effort, diabaikan bila gagal).
  Future<void> heartbeat();

  /// Lepas lock saat sesi selesai / keluar (best-effort).
  Future<void> endSession();
}
