import 'dart:io';

import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/data/quran_local_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/data/transcription_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/recitation_matcher.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';

class RecitationRepositoryImpl implements RecitationRepository {
  final QuranLocalDataSource local;
  final TranscriptionRemoteDataSource remote;

  RecitationRepositoryImpl({required this.local, required this.remote});

  @override
  Future<Either<Failure, List<SurahInfo>>> getSurahList() async {
    try {
      return Right(await local.getSurahList());
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat daftar surah: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> getAyatRange({
    required int surahId,
    required int from,
    required int to,
  }) async {
    try {
      return Right(await local.getAyatRange(
        surahId: surahId,
        from: from,
        to: to,
      ));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat ayat: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> getPageAyat({
    required int surahId,
    required int from,
    required int to,
  }) async {
    try {
      return Right(await local.getPageAyat(
        surahId: surahId,
        from: from,
        to: to,
      ));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat halaman mushaf: $e'));
    }
  }

  @override
  Future<Either<Failure, RecitationResult>> checkRecitation({
    required List<Ayah> targetAyat,
    required String audioFilePath,
    required String mimeType,
  }) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        return const Left(UnknownFailure('Berkas rekaman tidak ditemukan.'));
      }
      final bytes = await file.readAsBytes();

      final transcription = await remote.transcribe(
        audioBytes: bytes,
        mimeType: mimeType,
      );
      if (transcription.isEmpty) {
        return const Left(
          ServerFailure('Transkripsi kosong. Coba rekam ulang lebih jelas.'),
        );
      }

      final referenceText = targetAyat.map((a) => a.text).join(' ');
      final result = RecitationMatcher.compare(
        referenceText: referenceText,
        spokenText: transcription,
        transcription: transcription,
      );
      return Right(result);
    } on TranscriptionException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Gagal memeriksa bacaan: $e'));
    }
  }
}
