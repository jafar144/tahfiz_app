import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/monthly_report/data/datasources/monthly_report_remote_datasource.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';

class MonthlyReportRepositoryImpl implements MonthlyReportRepository {
  final MonthlyReportRemoteDataSource remoteDataSource;

  MonthlyReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  }) async {
    try {
      final result = await remoteDataSource.getReportsBySantri(
        santriId,
        bulan: bulan,
        tahun: tahun,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonthlyReport?>> getLatestReportBySantri(String santriId) async {
    try {
      final result = await remoteDataSource.getLatestReportBySantri(santriId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  ) async {
    try {
      final result = await remoteDataSource.getReportsByAsatidz(asatidzId, bulan, tahun);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonthlyReport?>> getReport(
    String santriId,
    int bulan,
    int tahun,
  ) async {
    try {
      final result = await remoteDataSource.getReport(santriId, bulan, tahun);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonthlyReport>> createOrUpdateReport(MonthlyReport report) async {
    try {
      final result = await remoteDataSource.createOrUpdateReport(report);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getReportedSantriIds(int bulan, int tahun) async {
    try {
      final result = await remoteDataSource.getReportedSantriIds(bulan, tahun);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
