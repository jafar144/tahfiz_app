import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:khoirunnasyien/features/payment/data/models/payment_model.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;

  PaymentRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<PaymentEntity>> getPayments(String month, String year) async {
    final intMonth = int.tryParse(month);
    final intYear = int.tryParse(year);
    final paddedMonth = month.padLeft(2, '0');

    final queries = [
      firestore
          .collection('payments')
          .where('bulan', isEqualTo: month)
          .where('tahun', isEqualTo: year)
          .get(),
      if (intMonth != null && intYear != null)
        firestore
            .collection('payments')
            .where('bulan', isEqualTo: intMonth)
            .where('tahun', isEqualTo: intYear)
            .get(),
      if (intYear != null)
        firestore
            .collection('payments')
            .where('bulan', isEqualTo: month)
            .where('tahun', isEqualTo: intYear)
            .get(),
      if (intMonth != null)
        firestore
            .collection('payments')
            .where('bulan', isEqualTo: intMonth)
            .where('tahun', isEqualTo: year)
            .get(),
      firestore
          .collection('payments')
          .where('bulan', isEqualTo: paddedMonth)
          .where('tahun', isEqualTo: year)
          .get(),
      if (intYear != null)
        firestore
            .collection('payments')
            .where('bulan', isEqualTo: paddedMonth)
            .where('tahun', isEqualTo: intYear)
            .get(),
    ];

    final results = await Future.wait(queries);
    final allDocs = results.expand((snapshot) => snapshot.docs).toList();

    final uniqueDocs = <String, DocumentSnapshot>{};
    for (var doc in allDocs) {
      uniqueDocs[doc.id] = doc;
    }

    return uniqueDocs.values
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList();
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
  Future<List<PaymentEntity>> getPaymentBySantri(
    String santriId,
    String month,
    String year,
  ) async {
    final intMonth = int.tryParse(month);
    final intYear = int.tryParse(year);
    final paddedMonth = month.padLeft(2, '0');

    final queries = [
      firestore
          .collection('payments')
          .where('santri_id', isEqualTo: santriId)
          .where('bulan', isEqualTo: month)
          .where('tahun', isEqualTo: year)
          .get(),
      if (intMonth != null && intYear != null)
        firestore
            .collection('payments')
            .where('santri_id', isEqualTo: santriId)
            .where('bulan', isEqualTo: intMonth)
            .where('tahun', isEqualTo: intYear)
            .get(),
      if (intYear != null)
        firestore
            .collection('payments')
            .where('santri_id', isEqualTo: santriId)
            .where('bulan', isEqualTo: month)
            .where('tahun', isEqualTo: intYear)
            .get(),
      if (intMonth != null)
        firestore
            .collection('payments')
            .where('santri_id', isEqualTo: santriId)
            .where('bulan', isEqualTo: intMonth)
            .where('tahun', isEqualTo: year)
            .get(),
      firestore
          .collection('payments')
          .where('santri_id', isEqualTo: santriId)
          .where('bulan', isEqualTo: paddedMonth)
          .where('tahun', isEqualTo: year)
          .get(),
      if (intYear != null)
        firestore
            .collection('payments')
            .where('santri_id', isEqualTo: santriId)
            .where('bulan', isEqualTo: paddedMonth)
            .where('tahun', isEqualTo: intYear)
            .get(),
    ];

    final results = await Future.wait(queries);
    final allDocs = results.expand((snapshot) => snapshot.docs).toList();

    final uniqueDocs = <String, DocumentSnapshot>{};
    for (var doc in allDocs) {
      uniqueDocs[doc.id] = doc;
    }

    return uniqueDocs.values
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<PaymentEntity>> getPaymentHistoryBySantri(
    String santriId,
    int? limit,
  ) async {
    Query query = firestore
        .collection('payments')
        .where('santri_id', isEqualTo: santriId)
        .orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<PaymentEntity>> getPaymentHistory({
    int limit = 10,
    String? lastDocumentId,
  }) async {
    Query query = firestore
        .collection('payments')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (lastDocumentId != null) {
      final lastDoc = await firestore
          .collection('payments')
          .doc(lastDocumentId)
          .get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
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

  @override
  Future<void> addPayments(List<PaymentEntity> payments) async {
    if (payments.isEmpty) return;

    final batch = firestore.batch();
    final collection = firestore.collection('payments');

    for (final payment in payments) {
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
      batch.set(collection.doc(), model.toMap());
    }

    await batch.commit();
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    await firestore.collection('payments').doc(paymentId).delete();
  }
}
