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
    required super.createdAt,
    required super.updatedAt,
  });

  factory MonthlyReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyReportModel(
      id: doc.id,
      asatidzId: data['asatidz_id'] ?? '',
      asatidzName: data['asatidz_name'] ?? '',
      asatidzGender: data['asatidz_gender'] ?? '',
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      bulan: data['bulan'] ?? 1,
      tahun: data['tahun'] ?? 2026,
      hafalanTerakhir: data['hafalan_terakhir'] ?? '',
      nilaiPerkembangan: data['nilai_perkembangan'] ?? 0,
      nilaiAkhlaq: data['nilai_akhlaq'] ?? 0,
      notes: data['notes'] ?? '',
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
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
