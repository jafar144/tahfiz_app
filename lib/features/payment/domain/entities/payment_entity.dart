

class PaymentEntity {
  final String id;
  final String santriId;
  final String bulan;
  final String tahun;
  final int total;
  final String method;
  final DateTime createdAt;
  final String createdBy;
  // Optional: Santri Name (joined client side or fetched)
  final String? santriName;

  PaymentEntity({
    required this.id,
    required this.santriId,
    required this.bulan,
    required this.tahun,
    required this.total,
    required this.method,
    required this.createdAt,
    required this.createdBy,
    this.santriName,
  });
}
