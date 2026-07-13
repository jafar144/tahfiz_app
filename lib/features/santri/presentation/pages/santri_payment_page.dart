import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_state.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_year_view.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriPaymentPage extends StatefulWidget {
  final DateTime? startDate;
  final String? santriId;
  const SantriPaymentPage({super.key, this.startDate, this.santriId});

  @override
  State<SantriPaymentPage> createState() => _SantriPaymentPageState();
}

class _SantriPaymentPageState extends State<SantriPaymentPage> {
  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  void _loadPaymentHistory() {
    final santriId = widget.santriId;
    if (santriId != null) {
      context.read<SantriPaymentHistoryCubit>().loadHistory(santriId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AiwaAppBar(title: 'Data Pembayaran'),
      body: BlocBuilder<SantriPaymentHistoryCubit, SantriPaymentHistoryState>(
        builder: (context, state) {
          if (state is SantriPaymentHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SantriPaymentHistoryError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is SantriPaymentHistoryLoaded) {
            return _buildContent(state.payments);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(List<PaymentEntity> payments) {
    final paidData = _transformPaymentData(payments);

    return RefreshIndicator(
      onRefresh: () async => _loadPaymentHistory(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: PaymentYearView(
                paidData: paidData,
                startDate: widget.startDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, Set<int>> _transformPaymentData(List<PaymentEntity> payments) {
    final Map<int, Set<int>> paidData = {};
    for (var payment in payments) {
      final year = int.tryParse(payment.tahun) ?? 0;
      final month = int.tryParse(payment.bulan) ?? 0;
      
      if (year > 0 && month > 0) {
        paidData.putIfAbsent(year, () => <int>{});
        paidData[year]!.add(month);
      }
    }
    return paidData;
  }
}
