import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';

class SantriSetoranModel extends SantriSetoran {
  SantriSetoranModel({
    required super.id,
    required super.santriId,
    required super.santriName,
    required super.halaqahId,
    required super.halaqahName,
    required super.asatidzId,
    required super.asatidzName,
    required super.date,
    required super.surah,
    required super.ayatAwal,
    required super.ayatAkhir,
    required super.kualitasHafalan,
    super.catatan,
    required super.createdAt,
  });

  factory SantriSetoranModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SantriSetoranModel(
      id: doc.id,
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      halaqahId: data['halaqah_id'] ?? '',
      halaqahName: data['halaqah_name'] ?? '',
      asatidzId: data['asatidz_id'] ?? '',
      asatidzName: data['asatidz_name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      surah: data['surah'] ?? '',
      ayatAwal: data['ayat_awal'] ?? 1,
      ayatAkhir: data['ayat_akhir'] ?? 1,
      kualitasHafalan: data['kualitas_hafalan'] ?? '',
      catatan: data['catatan'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santri_id': santriId,
      'santri_name': santriName,
      'halaqah_id': halaqahId,
      'halaqah_name': halaqahName,
      'asatidz_id': asatidzId,
      'asatidz_name': asatidzName,
      'date': Timestamp.fromDate(date),
      'surah': surah,
      'ayat_awal': ayatAwal,
      'ayat_akhir': ayatAkhir,
      'kualitas_hafalan': kualitasHafalan,
      'catatan': catatan,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
