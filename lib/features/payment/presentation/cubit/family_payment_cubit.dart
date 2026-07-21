import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';

part 'family_payment_state.dart';

/// Mengelola konteks pembayaran satu santri beserta saudara satu keluarganya
/// (jika ada), lengkap dengan riwayat bulan yang sudah dibayar tiap anggota.
class FamilyPaymentCubit extends Cubit<FamilyPaymentState> {
  final FamilyRepository familyRepository;
  final SantriRepository santriRepository;
  final PaymentRepository paymentRepository;

  FamilyPaymentCubit({
    required this.familyRepository,
    required this.santriRepository,
    required this.paymentRepository,
  }) : super(FamilyPaymentInitial());

  /// Cari saudara satu keluarga dari [primary], muat riwayat bayar tiap anggota
  /// yang masih aktif & bukan gratis, lalu emit [FamilyPaymentLoaded].
  /// Primary selalu berada di indeks 0.
  Future<void> resolve(SantriEntity primary) async {
    emit(FamilyPaymentLoading());
    try {
      final family = await familyRepository.getFamilyBySantriId(primary.id);
      final ids = <String>{primary.id, ...?family?.santriIds};

      List<SantriEntity> santris;
      if (ids.length <= 1) {
        santris = [primary];
      } else {
        final fetched = await santriRepository.getSantriByIds(ids.toList());
        // Hanya anggota aktif & reguler (bukan gratis) yang ditagih.
        final billable = fetched.where((s) => s.isActive && !s.isFree).toList();
        final primaryEntity = billable.firstWhere(
          (s) => s.id == primary.id,
          orElse: () => primary,
        );
        final others = billable.where((s) => s.id != primary.id).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        santris = [primaryEntity, ...others];
      }

      final members = <FamilyMemberPayment>[];
      for (final s in santris) {
        final history = await paymentRepository.getPaymentHistoryBySantri(
          s.id,
          null,
        );
        final paid = <int, Set<int>>{};
        for (final p in history) {
          final y = int.tryParse(p.tahun);
          final m = int.tryParse(p.bulan);
          if (y != null && m != null) {
            paid.putIfAbsent(y, () => <int>{}).add(m);
          }
        }
        members.add(FamilyMemberPayment(santri: s, paid: paid));
      }

      emit(FamilyPaymentLoaded(members));
    } catch (e) {
      emit(FamilyPaymentError(ErrorHandler.getMessage(e)));
    }
  }

  void reset() => emit(FamilyPaymentInitial());
}
