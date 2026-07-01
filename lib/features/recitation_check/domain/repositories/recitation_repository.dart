import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';

abstract class RecitationRepository {
  /// Daftar 114 surah untuk pemilihan target.
  Future<Either<Failure, List<SurahInfo>>> getSurahList();

  /// Ayat-ayat pada rentang [from]..[to] (inklusif) dari surah [surahId].
  Future<Either<Failure, List<Ayah>>> getAyatRange({
    required int surahId,
    required int from,
    required int to,
  });

  /// Semua ayat pada halaman mushaf yang memuat rentang target — termasuk
  /// surah tetangga di halaman itu, untuk ditampilkan sebagai halaman penuh.
  Future<Either<Failure, List<Ayah>>> getPageAyat({
    required int surahId,
    required int from,
    required int to,
  });

  /// Transkripsi audio lalu cocokkan dengan teks [targetAyat].
  /// [audioFilePath] = file rekaman lokal, [mimeType] mis. "audio/mp4".
  Future<Either<Failure, RecitationResult>> checkRecitation({
    required List<Ayah> targetAyat,
    required String audioFilePath,
    required String mimeType,
  });
}
