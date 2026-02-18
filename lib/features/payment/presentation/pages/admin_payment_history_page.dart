import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/admin_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/admin_payment_history_state.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_list_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminPaymentHistoryPage extends StatelessWidget {
  const AdminPaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminPaymentHistoryCubit(getIt<PaymentRepository>())..loadHistory(),
      child: const AdminPaymentHistoryView(),
    );
  }
}

class AdminPaymentHistoryView extends StatefulWidget {
  const AdminPaymentHistoryView({super.key});

  @override
  State<AdminPaymentHistoryView> createState() => _AdminPaymentHistoryViewState();
}

class _AdminPaymentHistoryViewState extends State<AdminPaymentHistoryView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AdminPaymentHistoryCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AiwaAppBar(title: 'Riwayat SPP'),
      body: BlocBuilder<AdminPaymentHistoryCubit, AdminPaymentHistoryState>(
        builder: (context, state) {
          if (state is AdminPaymentHistoryLoading) {
            return _buildSkeletonList();
          }

          if (state is AdminPaymentHistoryError) {
            return Center(child: Text(state.message));
          }

          if (state is AdminPaymentHistoryLoaded) {
            if (state.payments.isEmpty) {
              return const Center(child: Text('Belum ada riwayat transaksi.'));
            }

            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.hasReachedMax 
                  ? state.payments.length 
                  : state.payments.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8), // Replaced Divider with SizedBox for cleaner look or consistent with AdminPaymentPage which uses SizedBox(height: 16)
              itemBuilder: (context, index) {
                if (index >= state.payments.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                // Calculate if transaction is older than 30 days
                final isOldTransaction = DateTime.now().difference(state.payments[index].createdAt).inDays > 30;

                return Dismissible(
                  key: Key(state.payments[index].id),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: {
                    DismissDirection.endToStart: 0.6,
                  },
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  ),
                  confirmDismiss: (direction) async {
                    if (isOldTransaction) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Tidak Dapat Menghapus'),
                          content: const Text('Transaksi yang sudah lebih dari 1 bulan tidak dapat dihapus demi keamanan data.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return false;
                    }

                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Transaksi'),
                        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini? Data yang dihapus tidak dapat dikembalikan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    context.read<AdminPaymentHistoryCubit>().deletePayment(state.payments[index].id);
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: PaymentListItem(payment: state.payments[index])
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) {
          // Mock data for skeleton
          final mockPayment = PaymentEntity(
            id: '1',
            santriId: '1',
            bulan: '1',
            tahun: '2024',
            total: 100000,
            method: 'cash',
            createdAt: DateTime.now(),
            createdBy: 'admin',
            santriName: 'Santri Name',
          );
          return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)
            ),
            child: PaymentListItem(payment: mockPayment),
          );
        },
      ),
    );
  }
}
