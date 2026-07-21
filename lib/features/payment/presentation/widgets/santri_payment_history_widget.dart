import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriPaymentHistoryWidget extends StatelessWidget {
  const SantriPaymentHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SantriPaymentHistoryCubit, SantriPaymentHistoryState>(
      builder: (context, state) {
        if (state is SantriPaymentHistoryInitial) {
          return const SizedBox.shrink();
        }

        if (state is SantriPaymentHistoryError) {
          return Text(
            'Gagal memuat history: ${state.message}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final isLoading = state is SantriPaymentHistoryLoading;
        final payments = state is SantriPaymentHistoryLoaded
            ? state.payments
            : [];

        if (!isLoading && payments.isEmpty) {
          return const Text(
            'Belum ada riwayat pembayaran',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Pembayaran Terakhir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Skeletonizer(
              enabled: isLoading,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: isLoading ? 3 : payments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (isLoading) {
                    return Container(
                      color: Colors.white,
                      child: ListTile(
                        dense: true,
                        title: const Text('Januari 2024'),
                        subtitle: const Text('01 Jan 2024, 10:00'),
                        trailing: const Text('Rp 200.000'),
                      ),
                    );
                  }

                  final payment = payments[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: _getBorderRadius(index, payments.length),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      title: Text(
                        '${DateFormat('MMMM', 'id_ID').format(DateTime(2024, int.tryParse(payment.bulan) ?? 1))} ${payment.tahun}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                          'id_ID',
                        ).format(payment.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(payment.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  BorderRadius _getBorderRadius(int index, int length) {
    if (length == 1) return BorderRadius.circular(12);
    if (index == 0) {
      return const BorderRadius.vertical(top: Radius.circular(12));
    }
    if (index == length - 1) {
      return const BorderRadius.vertical(bottom: Radius.circular(12));
    }
    return BorderRadius.zero;
  }
}
