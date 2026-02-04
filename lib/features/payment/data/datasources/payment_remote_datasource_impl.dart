import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:khoirunnasyien/features/payment/data/models/payment_model.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;

  PaymentRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<PaymentEntity>> getPayments(String month, String year) async {
    final snapshot = await firestore
        .collection('payments')
        .where('bulan', isEqualTo: month)
        .where('tahun', isEqualTo: year)
        .get();

    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<PaymentEntity>> getRecentPayments(int limit) async {
    final snapshot = await firestore
        .collection('payments')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<PaymentEntity>> getPaymentBySantri(String santriId, String month, String year) async {
    final snapshot = await firestore
        .collection('payments')
        .where('santri_id', isEqualTo: santriId)
        .where('bulan', isEqualTo: month)
        .where('tahun', isEqualTo: year)
        .get();

    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> addPayment(PaymentEntity payment) async {
    final model = PaymentModel(
      id: '', // Not used for add
      santriId: payment.santriId,
      bulan: payment.bulan,
      tahun: payment.tahun,
      total: payment.total,
      method: payment.method,
      createdAt: payment.createdAt,
      createdBy: payment.createdBy,
    );
    
    await firestore.collection('payments').add(model.toMap());
  }
}
