import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  PaymentModel({
    required super.id,
    required super.santriId,
    required super.bulan,
    required super.tahun,
    required super.total,
    required super.method,
    required super.createdAt,
    required super.createdBy,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      santriId: data['santri_id'] ?? '',
      bulan: data['bulan'] ?? '',
      tahun: data['tahun'] ?? '',
      total: (data['total'] ?? 0).toInt(),
      method: data['metode'] ?? 'Manual',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'santri_id': santriId,
      'bulan': bulan,
      'tahun': tahun,
      'total': total,
      'metode': method,
      'created_at': FieldValue.serverTimestamp(),
      'created_by': createdBy,
    };
  }
}
