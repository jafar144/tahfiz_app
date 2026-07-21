import 'package:dart_either/dart_either.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class MonthlyReportRepository {
  Future<Either<Failure, List<MonthlyReport>>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  });

  Future<Either<Failure, MonthlyReport?>> getLatestReportBySantri(
    String santriId,
  );

  Future<Either<Failure, List<MonthlyReport>>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  );

  Future<Either<Failure, MonthlyReport?>> getReport(
    String santriId,
    int bulan,
    int tahun,
  );

  Future<Either<Failure, MonthlyReport>> createOrUpdateReport(
    MonthlyReport report,
  );

  Future<Either<Failure, Set<String>>> getReportedSantriIds(
    int bulan,
    int tahun,
  );
}
