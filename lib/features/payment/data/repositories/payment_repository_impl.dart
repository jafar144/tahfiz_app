import 'package:khoirunnasyien/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final SantriRepository santriRepository;

  PaymentRepositoryImpl(this.remoteDataSource, this.santriRepository);

  @override
  Future<List<PaymentEntity>> getPayments(String month, String year) async {
    final payments = await remoteDataSource.getPayments(month, year);
    
    // We might want to join Santri names here to optimize, avoiding N+1 in UI
    // For now, let's keep it simple. Optimization: fetch santri names in Batch or reuse cached.
    // The requirement says "recent transactions" shows name.
    
    // Let's enhance current payments with Santri Names manually for now.
    // But getPayments return PaymentEntity.
    // Ideally, we fetch santri details.
    
    // For simplicity, we will fetch santri details in Cubit or assume ID is enough for now, 
    // but the UI shows names.
    // Let's modify this to fetch name if possible, OR just return raw payments and let Cubit handle it.
    // The Cubit will fetch ALL santri anyway to calculate unpaid users. 
    // So we can map ID to Name in Cubit.
    
    return payments;
  }

  @override
  Future<List<PaymentEntity>> getRecentPayments(int limit) async {
    final payments = await remoteDataSource.getRecentPayments(limit);
    // Here we definitely need names.
    // We can fetch santri details for each payment.
    final List<PaymentEntity> enrichedPayments = [];
    
    for (var p in payments) {
      try {
        final santri = await santriRepository.getSantriDetail(p.santriId);
        enrichedPayments.add(PaymentEntity(
          id: p.id,
          santriId: p.santriId,
          bulan: p.bulan,
          tahun: p.tahun,
          total: p.total,
          method: p.method,
          createdAt: p.createdAt,
          createdBy: p.createdBy,
          santriName: santri.name,
        ));
      } catch (e) {
         enrichedPayments.add(p); // Fallback if santri not found
      }
    }
    return enrichedPayments;
  }

  @override
  Future<List<PaymentEntity>> getPaymentBySantri(String santriId, String month, String year) {
    return remoteDataSource.getPaymentBySantri(santriId, month, year);
  }

  @override
  Future<List<PaymentEntity>> getPaymentHistoryBySantri(String santriId, int? limit) {
    return remoteDataSource.getPaymentHistoryBySantri(santriId, limit);
  }

  @override
  Future<List<PaymentEntity>> getPaymentHistory({int limit = 10, String? lastDocumentId}) async {
    final payments = await remoteDataSource.getPaymentHistory(limit: limit, lastDocumentId: lastDocumentId);
    
    // Enrich with Santri details
    final List<PaymentEntity> enrichedPayments = [];
    
    // Optimization: we could fetch all unique santri IDs in one go if API supported it, but here we loop
    for (var p in payments) {
      try {
        final santri = await santriRepository.getSantriDetail(p.santriId);
        enrichedPayments.add(PaymentEntity(
          id: p.id,
          santriId: p.santriId,
          bulan: p.bulan,
          tahun: p.tahun,
          total: p.total,
          method: p.method,
          createdAt: p.createdAt,
          createdBy: p.createdBy,
          santriName: santri.name,
        ));
      } catch (e) {
         enrichedPayments.add(p);
      }
    }
    return enrichedPayments;
  }

  @override
  Future<void> addPayment(PaymentEntity payment) async {
    await remoteDataSource.addPayment(payment);
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    await remoteDataSource.deletePayment(paymentId);
  }
}
