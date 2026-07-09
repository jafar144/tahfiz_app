import 'package:dart_either/dart_either.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

abstract class SurahJourneyRepository {
  /// Progres seluruh peta (per surah) + total XP milik pengguna saat ini.
  Future<Either<Failure, JourneyProgress>> getProgress();

  /// Simpan hasil TEST SATU BAGIAN; [xpDelta] langsung ditambahkan ke total
  /// XP. Kembalikan progres surah TERBARU.
  Future<Either<Failure, SurahProgress>> saveSectionResult({
    required int surahId,
    required String sectionId,
    required int correct,
    required bool passed,
    required int xpDelta,
  });

  /// Simpan hasil UJIAN AKHIR surah; lulus → surah selesai (centang hijau).
  Future<Either<Failure, SurahProgress>> saveExamResult({
    required int surahId,
    required int score,
    required bool passed,
    required int xpDelta,
  });

  /// Seluruh ayat surah [surahId] (untuk halaman belajar & penyusunan soal).
  Future<Either<Failure, List<Ayah>>> getSurahAyat(int surahId);

  /// Susun soal test untuk SATU BAGIAN sesuai `SectionTest`-nya.
  Future<Either<Failure, List<LessonQuestion>>> generateSectionTest(
    SurahLesson lesson,
    LessonSection section,
  );

  /// Susun soal UJIAN AKHIR surah (komposisi di `LessonConfig`; soal pilihan
  /// diundi dari gabungan bank semua bagian + soal kosa kata).
  Future<Either<Failure, List<LessonQuestion>>> generateExam(
    SurahLesson lesson,
  );

  /// Periksa rekaman bacaan terhadap ayat jawaban (delegasi mesin Uji Bacaan).
  Future<Either<Failure, RecitationResult>> checkRecitation({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  });
}
