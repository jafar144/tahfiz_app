import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';

part 'input_payment_state.dart';

class InputPaymentCubit extends Cubit<InputPaymentState> {
  final PaymentRepository paymentRepository;

  InputPaymentCubit(this.paymentRepository) : super(InputPaymentInitial());

  Future<void> validateAndSubmitPayment({
    required String santriId,
    required String month,
    required String year,
    required int total,
    required String createdBy,
    required DateTime date,
  }) async {
    emit(InputPaymentLoading());

    try {
      final existingPayments = await paymentRepository.getPaymentBySantri(
        santriId,
        month,
        year,
      );

      if (existingPayments.isNotEmpty) {
        emit(InputPaymentAlreadyExists(existingPayments.first));
        return;
      }

      final payment = PaymentEntity(
        id: '',
        santriId: santriId,
        bulan: month,
        tahun: year,
        total: total,
        method: 'Manual',
        createdAt: date,
        createdBy: createdBy,
      );

      await paymentRepository.addPayment(payment);
      emit(InputPaymentSuccess());
    } catch (e) {
      emit(InputPaymentFailure(e.toString()));
    }
  }

  /// Menyimpan pembayaran untuk beberapa bulan sekaligus dalam satu batch.
  ///
  /// [periods] berisi daftar `DateTime(tahun, bulan)` yang dipilih. Bulan yang
  /// ternyata sudah dibayar (mis. data UI basi) otomatis dilewati agar tidak
  /// terjadi pembayaran ganda.
  Future<void> submitMultiplePayments({
    required String santriId,
    required List<DateTime> periods,
    required int totalPerMonth,
    required String createdBy,
    required DateTime date,
  }) async {
    if (periods.isEmpty) {
      emit(InputPaymentFailure('Pilih minimal satu bulan untuk dibayar'));
      return;
    }

    emit(InputPaymentLoading());

    try {
      // Safety net: lewati bulan yang sudah dibayar untuk mencegah double charge.
      final existing =
          await paymentRepository.getPaymentHistoryBySantri(santriId, null);
      final paidKeys = existing
          .map((p) => '${int.tryParse(p.tahun)}-${int.tryParse(p.bulan)}')
          .toSet();

      final payments = <PaymentEntity>[];
      for (final period in periods) {
        final key = '${period.year}-${period.month}';
        if (paidKeys.contains(key)) continue;

        payments.add(PaymentEntity(
          id: '',
          santriId: santriId,
          bulan: period.month.toString(),
          tahun: period.year.toString(),
          total: totalPerMonth,
          method: 'Manual',
          createdAt: date,
          createdBy: createdBy,
        ));
      }

      if (payments.isEmpty) {
        emit(InputPaymentFailure('Semua bulan yang dipilih sudah dibayar'));
        return;
      }

      await paymentRepository.addPayments(payments);
      emit(InputPaymentSuccess(count: payments.length));
    } catch (e) {
      emit(InputPaymentFailure(e.toString()));
    }
  }

  void reset() {
    emit(InputPaymentInitial());
  }
}
