part of 'family_payment_cubit.dart';

/// Satu anggota keluarga beserta bulan-bulan yang sudah dibayar.
class FamilyMemberPayment {
  final SantriEntity santri;

  /// Bulan yang sudah dibayar, dikelompokkan per tahun (`{tahun: {bulan}}`).
  final Map<int, Set<int>> paid;

  const FamilyMemberPayment({required this.santri, required this.paid});

  bool isPaidPeriod(DateTime period) =>
      paid[period.year]?.contains(period.month) ?? false;
}

abstract class FamilyPaymentState {}

class FamilyPaymentInitial extends FamilyPaymentState {}

class FamilyPaymentLoading extends FamilyPaymentState {}

class FamilyPaymentError extends FamilyPaymentState {
  final String message;
  FamilyPaymentError(this.message);
}

class FamilyPaymentLoaded extends FamilyPaymentState {
  /// Anggota yang wajib bayar (aktif & bukan gratis); primary di indeks 0.
  final List<FamilyMemberPayment> members;

  FamilyPaymentLoaded(this.members);

  FamilyMemberPayment get primary => members.first;

  /// True bila ada lebih dari satu santri yang bisa ditagih (punya saudara).
  bool get isFamily => members.length > 1;
}
