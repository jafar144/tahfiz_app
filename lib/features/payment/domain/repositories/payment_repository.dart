import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<List<PaymentEntity>> getPayments(String month, String year);
  Future<List<PaymentEntity>> getRecentPayments(int limit);
  Future<List<PaymentEntity>> getPaymentBySantri(String santriId, String month, String year);
  Future<List<PaymentEntity>> getPaymentHistoryBySantri(String santriId, int limit);
  Future<List<PaymentEntity>> getPaymentHistory({int limit = 10, String? lastDocumentId});
  Future<void> addPayment(PaymentEntity payment);
}
