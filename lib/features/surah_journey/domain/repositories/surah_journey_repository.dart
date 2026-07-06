import 'package:dart_either/dart_either.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

abstract class SurahJourneyRepository {
  /// Progres seluruh peta milik pengguna saat ini.
  Future<Either<Failure, JourneyProgress>> getProgress();

  /// Tandai surah [surahId] sudah dipelajari (halaman belajar dituntaskan).
  Future<Either<Failure, void>> markLearned(int surahId);

  /// Simpan hasil ujian; kembalikan progres surah TERBARU (best score &
  /// status selesai sudah diperhitungkan).
  Future<Either<Failure, SurahProgress>> saveTestResult({
    required int surahId,
    required int score,
  });

  /// Seluruh ayat surah [surahId] (untuk halaman belajar & penyusunan soal).
  Future<Either<Failure, List<Ayah>>> getSurahAyat(int surahId);

  /// Susun soal ujian untuk [lesson] (campuran suara + pilihan materi).
  Future<Either<Failure, List<LessonQuestion>>> generateTest(
    SurahLesson lesson,
  );

  /// Periksa rekaman bacaan terhadap ayat jawaban (delegasi mesin Uji Bacaan).
  Future<Either<Failure, RecitationResult>> checkRecitation({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  });
}
