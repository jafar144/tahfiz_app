import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

class MonthlyReportModel extends MonthlyReport {
  MonthlyReportModel({
    required super.id,
    required super.asatidzId,
    required super.asatidzName,
    super.asatidzGender,
    required super.santriId,
    required super.santriName,
    required super.bulan,
    required super.tahun,
    required super.hafalanTerakhir,
    required super.nilaiPerkembangan,
    required super.nilaiAkhlaq,
    super.notes,
    super.target,
    super.targetEvaluation,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MonthlyReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyReportModel.fromMap(id: doc.id, data: data);
  }

  /// Parser terpisah agar kompatibilitas dokumen lama dapat diuji tanpa
  /// memerlukan emulator Firestore.
  factory MonthlyReportModel.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return MonthlyReportModel(
      id: id,
      asatidzId: data['asatidz_id'] ?? '',
      asatidzName: data['asatidz_name'] ?? '',
      asatidzGender: data['asatidz_gender'] ?? '',
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      bulan: data['bulan'] ?? 1,
      tahun: data['tahun'] ?? 2026,
      hafalanTerakhir: data['hafalan_terakhir'] ?? '',
      nilaiPerkembangan: _parseNilai(data['nilai_perkembangan']),
      nilaiAkhlaq: _parseNilai(data['nilai_akhlaq']),
      notes: data['notes'] ?? '',
      target: _parseTarget(data['monthly_target']),
      targetEvaluation: _parseTargetEvaluation(data['target_evaluation']),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Salinan model dengan gender pengajar terisi (dipakai saat join ke profil asatidz).
  MonthlyReportModel withAsatidzGender(String gender) => MonthlyReportModel(
    id: id,
    asatidzId: asatidzId,
    asatidzName: asatidzName,
    asatidzGender: gender,
    santriId: santriId,
    santriName: santriName,
    bulan: bulan,
    tahun: tahun,
    hafalanTerakhir: hafalanTerakhir,
    nilaiPerkembangan: nilaiPerkembangan,
    nilaiAkhlaq: nilaiAkhlaq,
    notes: notes,
    target: target,
    targetEvaluation: targetEvaluation,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, dynamic> toFirestore() {
    return {
      'asatidz_id': asatidzId,
      'asatidz_name': asatidzName,
      'asatidz_gender': asatidzGender,
      'santri_id': santriId,
      'santri_name': santriName,
      'bulan': bulan,
      'tahun': tahun,
      'hafalan_terakhir': hafalanTerakhir,
      'nilai_perkembangan': nilaiPerkembangan,
      'nilai_akhlaq': nilaiAkhlaq,
      'notes': notes,
      if (target != null)
        'monthly_target': {
          'bulan': target!.bulan,
          'tahun': target!.tahun,
          'minimum': target!.minimum,
          'optimum': target!.optimum,
        },
      if (targetEvaluation != null)
        'target_evaluation': {
          'source_report_id': targetEvaluation!.sourceReportId,
          'target_bulan': targetEvaluation!.targetBulan,
          'target_tahun': targetEvaluation!.targetTahun,
          'result': targetEvaluation!.result.storageValue,
          'evaluated_at': Timestamp.fromDate(targetEvaluation!.evaluatedAt),
        },
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Mengonversi nilai dari Firestore (int / num / String) menjadi int.
///
/// Data hasil impor dari sistem lama (MySQL) bisa bernilai 0 atau null saat
/// santri belum/ tidak dinilai. Sesuai kesepakatan, nilai 0 diperlakukan
/// sebagai 'Sangat Kurang' (setara nilai 1) agar tidak tampil '—'.
int _parseNilai(dynamic raw) {
  int value;
  if (raw is int) {
    value = raw;
  } else if (raw is num) {
    value = raw.toInt();
  } else if (raw is String) {
    value = int.tryParse(raw) ?? 0;
  } else {
    value = 0;
  }
  return value <= 0 ? 1 : value;
}

MonthlyTarget? _parseTarget(dynamic raw) {
  final data = _stringKeyedMap(raw);
  if (data == null) return null;

  final minimum = (data['minimum'] ?? '').toString().trim();
  final optimum = (data['optimum'] ?? '').toString().trim();
  final bulan = _parsePositiveInt(data['bulan']);
  final tahun = _parsePositiveInt(data['tahun']);
  if (minimum.isEmpty || optimum.isEmpty || bulan == null || tahun == null) {
    return null;
  }

  return MonthlyTarget(
    bulan: bulan,
    tahun: tahun,
    minimum: minimum,
    optimum: optimum,
  );
}

MonthlyTargetEvaluation? _parseTargetEvaluation(dynamic raw) {
  final data = _stringKeyedMap(raw);
  if (data == null) return null;

  final bulan = _parsePositiveInt(data['target_bulan']);
  final tahun = _parsePositiveInt(data['target_tahun']);
  final evaluatedAt = _parseDate(data['evaluated_at']);
  if (bulan == null || tahun == null || evaluatedAt == null) return null;

  return MonthlyTargetEvaluation(
    sourceReportId: (data['source_report_id'] ?? '').toString(),
    targetBulan: bulan,
    targetTahun: tahun,
    result: MonthlyTargetResult.fromStorage(data['result']),
    evaluatedAt: evaluatedAt,
  );
}

Map<String, dynamic>? _stringKeyedMap(dynamic raw) {
  if (raw is! Map) return null;
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

int? _parsePositiveInt(dynamic raw) {
  final value = switch (raw) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value),
    _ => null,
  };
  return value != null && value > 0 ? value : null;
}

DateTime? _parseDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
