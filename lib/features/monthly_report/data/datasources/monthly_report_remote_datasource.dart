import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/monthly_report/data/models/monthly_report_model.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

abstract class MonthlyReportRemoteDataSource {
  Future<List<MonthlyReportModel>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  });

  Future<MonthlyReportModel?> getLatestReportBySantri(String santriId);

  Future<List<MonthlyReportModel>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  );

  Future<MonthlyReportModel?> getReport(String santriId, int bulan, int tahun);

  Future<MonthlyReportModel> createOrUpdateReport(MonthlyReport report);

  /// Mengembalikan kumpulan santri_id yang sudah dinilai pada bulan & tahun tertentu.
  Future<Set<String>> getReportedSantriIds(int bulan, int tahun);
}

class MonthlyReportRemoteDataSourceImpl
    implements MonthlyReportRemoteDataSource {
  final FirebaseFirestore firestore;

  MonthlyReportRemoteDataSourceImpl({required this.firestore});

  static const _collection = 'monthly_reports';

  @override
  Future<List<MonthlyReportModel>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  }) async {
    Query query = firestore
        .collection(_collection)
        .where('santri_id', isEqualTo: santriId);

    if (bulan != null) {
      query = query.where('bulan', isEqualTo: bulan);
    }
    if (tahun != null) {
      query = query.where('tahun', isEqualTo: tahun);
    }

    final snapshot = await query.get();
    final reports = snapshot.docs
        .map((doc) => MonthlyReportModel.fromFirestore(doc))
        .toList();

    reports.sort((a, b) {
      final yearComp = b.tahun.compareTo(a.tahun);
      if (yearComp != 0) return yearComp;
      return b.bulan.compareTo(a.bulan);
    });

    return _attachAsatidzGender(reports);
  }

  /// Melengkapi laporan dengan gender pengajar (untuk gelar Ustadz/Ustadzah)
  /// dengan join ke koleksi asatidz_profiles berdasarkan asatidz_id.
  Future<List<MonthlyReportModel>> _attachAsatidzGender(
    List<MonthlyReportModel> reports,
  ) async {
    if (reports.isEmpty) return reports;

    final ids = reports
        .map((r) => r.asatidzId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return reports;

    final genderById = <String, String>{};
    // whereIn maksimal 10 item per query.
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);
      final snapshot = await firestore
          .collection('asatidz_profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        genderById[doc.id] = (doc.data()['jenis_kelamin'] ?? '').toString();
      }
    }

    return reports
        .map((r) => r.withAsatidzGender(genderById[r.asatidzId] ?? ''))
        .toList();
  }

  @override
  Future<MonthlyReportModel?> getLatestReportBySantri(String santriId) async {
    final snapshot = await firestore
        .collection(_collection)
        .where('santri_id', isEqualTo: santriId)
        .orderBy('tahun', descending: true)
        .orderBy('bulan', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final model = MonthlyReportModel.fromFirestore(snapshot.docs.first);
    final enriched = await _attachAsatidzGender([model]);
    return enriched.first;
  }

  @override
  Future<List<MonthlyReportModel>> getReportsByAsatidz(
    String asatidzId,
    int bulan,
    int tahun,
  ) async {
    final snapshot = await firestore
        .collection(_collection)
        .where('asatidz_id', isEqualTo: asatidzId)
        .where('bulan', isEqualTo: bulan)
        .where('tahun', isEqualTo: tahun)
        .get();

    return snapshot.docs
        .map((doc) => MonthlyReportModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<MonthlyReportModel?> getReport(
    String santriId,
    int bulan,
    int tahun,
  ) async {
    final snapshot = await firestore
        .collection(_collection)
        .where('santri_id', isEqualTo: santriId)
        .where('bulan', isEqualTo: bulan)
        .where('tahun', isEqualTo: tahun)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return MonthlyReportModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<MonthlyReportModel> createOrUpdateReport(MonthlyReport report) async {
    final now = DateTime.now();

    final existing = await getReport(
      report.santriId,
      report.bulan,
      report.tahun,
    );

    if (existing != null) {
      final updateData = {
        'hafalan_terakhir': report.hafalanTerakhir,
        'nilai_perkembangan': report.nilaiPerkembangan,
        'nilai_akhlaq': report.nilaiAkhlaq,
        'notes': report.notes,
        'monthly_target': _targetToFirestore(report.target),
        'target_evaluation': _evaluationToFirestore(report.targetEvaluation),
        'updated_at': Timestamp.fromDate(now),
      };

      await firestore
          .collection(_collection)
          .doc(existing.id)
          .update(updateData);

      return MonthlyReportModel(
        id: existing.id,
        asatidzId: existing.asatidzId,
        asatidzName: existing.asatidzName,
        santriId: existing.santriId,
        santriName: existing.santriName,
        bulan: existing.bulan,
        tahun: existing.tahun,
        hafalanTerakhir: report.hafalanTerakhir,
        nilaiPerkembangan: report.nilaiPerkembangan,
        nilaiAkhlaq: report.nilaiAkhlaq,
        notes: report.notes,
        target: report.target,
        targetEvaluation: report.targetEvaluation,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
    }

    final model = MonthlyReportModel(
      id: '',
      asatidzId: report.asatidzId,
      asatidzName: report.asatidzName,
      santriId: report.santriId,
      santriName: report.santriName,
      bulan: report.bulan,
      tahun: report.tahun,
      hafalanTerakhir: report.hafalanTerakhir,
      nilaiPerkembangan: report.nilaiPerkembangan,
      nilaiAkhlaq: report.nilaiAkhlaq,
      notes: report.notes,
      target: report.target,
      targetEvaluation: report.targetEvaluation,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await firestore
        .collection(_collection)
        .add(model.toFirestore());

    return MonthlyReportModel(
      id: docRef.id,
      asatidzId: model.asatidzId,
      asatidzName: model.asatidzName,
      santriId: model.santriId,
      santriName: model.santriName,
      bulan: model.bulan,
      tahun: model.tahun,
      hafalanTerakhir: model.hafalanTerakhir,
      nilaiPerkembangan: model.nilaiPerkembangan,
      nilaiAkhlaq: model.nilaiAkhlaq,
      notes: model.notes,
      target: model.target,
      targetEvaluation: model.targetEvaluation,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Set<String>> getReportedSantriIds(int bulan, int tahun) async {
    final snapshot = await firestore
        .collection(_collection)
        .where('bulan', isEqualTo: bulan)
        .where('tahun', isEqualTo: tahun)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['santri_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }
}

Map<String, dynamic>? _targetToFirestore(MonthlyTarget? target) {
  if (target == null) return null;
  return {
    'bulan': target.bulan,
    'tahun': target.tahun,
    'minimum': target.minimum,
    'optimum': target.optimum,
  };
}

Map<String, dynamic>? _evaluationToFirestore(
  MonthlyTargetEvaluation? evaluation,
) {
  if (evaluation == null) return null;
  return {
    'source_report_id': evaluation.sourceReportId,
    'target_bulan': evaluation.targetBulan,
    'target_tahun': evaluation.targetTahun,
    'result': evaluation.result.storageValue,
    'evaluated_at': Timestamp.fromDate(evaluation.evaluatedAt),
  };
}
