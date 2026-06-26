import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_state.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/student_payment_list_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_wheel_picker.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_list_item.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

class AdminPaymentPage extends StatelessWidget {
  const AdminPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>()..loadDashboard(DateTime.now()),
      child: const AdminPaymentView(),
    );
  }
}

class AdminPaymentView extends StatefulWidget {
  const AdminPaymentView({super.key});

  @override
  State<AdminPaymentView> createState() => _AdminPaymentViewState();
}

class _AdminPaymentViewState extends State<AdminPaymentView> {
  int _displayedCount = 10;
  bool _isPaginating = false;
  final ScrollController _scrollController = ScrollController();

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

  void _onScroll() async {
    if (!_scrollController.hasClients || _isPaginating) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    
    if (currentScroll >= (maxScroll * 0.9)) {
      final cubit = context.read<PaymentCubit>();
      if (cubit.state is PaymentLoaded) {
         final totalItems = (cubit.state as PaymentLoaded).recentTransactions.length;
         if (_displayedCount < totalItems) {
            setState(() {
              _isPaginating = true;
            });
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) {
               setState(() {
                 _displayedCount += 10;
                 _isPaginating = false;
               });
            }
         }
      }
    }
  }
  
  void _showMonthYearPicker(BuildContext context, DateTime currentDate) {
    final now = DateTime.now();
    final years = List.generate(3, (index) => now.year - 1 + index);
    final months = List.generate(12, (index) => index + 1);

    int selectedYearIndex = years.indexOf(currentDate.year);
    if (selectedYearIndex == -1) selectedYearIndex = 0;
    
    int selectedMonthIndex = currentDate.month - 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              // Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => ctx.pop(),
                      child: const Text('Batal',
                          style: TextStyle(color: Colors.red)),
                    ),
                    const Text('Pilih Bulan & Tahun',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        final newDate = DateTime(
                          years[selectedYearIndex],
                          months[selectedMonthIndex],
                        );
                        context.pop();
                        setState(() {
                          _displayedCount = 10;
                        });
                        // Reload data
                        context.read<PaymentCubit>().loadDashboard(newDate);
                      },
                      child: const Text('Pilih',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Pickers
              Expanded(
                child: Row(
                  children: [
                    // Month Picker
                    Expanded(
                      flex: 3,
                      child: AiwaWheelPicker<int>(
                        initialItem: selectedMonthIndex,
                        items: months,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) => selectedMonthIndex = index,
                        itemBuilder: (m) => Text(
                          DateFormat('MMMM', 'id_ID').format(DateTime(2024, m)),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Year Picker
                    Expanded(
                      flex: 2,
                      child: AiwaWheelPicker<int>(
                        initialItem: selectedYearIndex,
                        items: years,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) => selectedYearIndex = index,
                        itemBuilder: (y) => Text(
                          y.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStudentList(
    BuildContext context, 
    List<SantriEntity> students, 
    String title,
    DateTime date, {
    bool showWhatsApp = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return StudentPaymentListBottomSheet(
            title: title,
            students: students,
            monthYear: DateFormat('MMMM yyyy', 'id_ID').format(date),
            showWhatsApp: showWhatsApp,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(title: 'Pembayaran'),
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          final isLoading = state is PaymentLoading;
          
          DateTime displayDateObj = DateTime.now();
          int paidCount = 0;
          int unpaidCount = 0;
          List<PaymentEntity> recentTransactions = [];
          
          if (state is PaymentLoaded) {
            displayDateObj = state.selectedDate;
            paidCount = state.paidCount;
            unpaidCount = state.unpaidCount;
            recentTransactions = state.recentTransactions;
          } else if (isLoading) {
             // Mock data for skeleton
             displayDateObj = DateTime.now();
             paidCount = 120;
             unpaidCount = 45;
             recentTransactions = List.generate(5, (index) => PaymentEntity(
               id: '1', santriId: '1', bulan: '1', tahun: '2025', total: 100000, 
               method: 'cash', createdAt: DateTime.now(), createdBy: 'admin', santriName: 'Nama Santri'
             ));
          }

          if (state is PaymentError) {
            return Center(child: Text(state.message));
          }

          final displayDate = DateFormat('MMMM yyyy', 'id_ID').format(displayDateObj);
            
          return Skeletonizer(
              enabled: isLoading,
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _displayedCount = 10;
                  });
                  context.read<PaymentCubit>().loadDashboard(displayDateObj);
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Selector
                      Center(
                        child: InkWell(
                          onTap: isLoading ? null : () => _showMonthYearPicker(context, displayDateObj),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  displayDate,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
            
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Sudah Bayar',
                              count: paidCount,
                              color: const Color(0xFF0CAF60), // Green
                              icon: Icons.check_circle_outline,
                              onTap: isLoading ? () {} : () => _showStudentList(
                                context, 
                                state is PaymentLoaded ? state.paidStudents : [], 
                                'Daftar Sudah Bayar',
                                displayDateObj,
                                showWhatsApp: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Belum Bayar',
                              count: unpaidCount,
                              color: const Color(0xFFFD5D6F), // Red
                              icon: Icons.pending_actions_outlined,
                              onTap: isLoading ? () {} : () => _showStudentList(
                                context, 
                                state is PaymentLoaded ? state.unpaidStudents : [], 
                                'Daftar Belum Bayar',
                                displayDateObj,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
            
                      // Transaction History Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Riwayat SPP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (!isLoading)
                          TextButton(
                            onPressed: () async {
                              await context.pushNamed(RouteNames.paymentHistory);
                              if (context.mounted) {
                                final cubit = context.read<PaymentCubit>();
                                final currentDate = cubit.state is PaymentLoaded
                                    ? (cubit.state as PaymentLoaded).selectedDate
                                    : DateTime.now();
                                cubit.loadDashboard(currentDate);
                              }
                            },
                            child: const Text('Lihat Semua', style: AppTextStyles.infoGrey),
                          ),
                        ],
                      ),
                      // Transaction List
                      if (!isLoading && recentTransactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('Belum ada transaksi baru.'),
                          ),
                        )
                      else 
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentTransactions.length > _displayedCount ? _displayedCount : recentTransactions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = recentTransactions[index];
                            final isOldTransaction = DateTime.now().difference(item.createdAt).inDays > 30;

                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              dismissThresholds: {
                                DismissDirection.endToStart: 0.5,
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
                                  return false; // Prevent dismiss
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
                                context.read<PaymentCubit>().deletePayment(item.id);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: PaymentListItem(payment: item),
                              ),
                            );
                          },
                        ),
                      if (_isPaginating)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Skeletonizer(
                            enabled: true,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200)
                              ),
                              child: PaymentListItem(
                                payment: PaymentEntity(
                                  id: '1', santriId: '1', bulan: '1', tahun: '2024', total: 100000, method: 'cash', createdAt: DateTime.now(), createdBy: 'admin', santriName: 'Loading Santri'
                                )
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
              ),
            );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushNamed(RouteNames.inputPayment);
          if (context.mounted) {
            context.read<PaymentCubit>().loadDashboard(
              context.read<PaymentCubit>().state is PaymentLoaded 
                  ? (context.read<PaymentCubit>().state as PaymentLoaded).selectedDate 
                  : DateTime.now()
            );
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140, // Height from design
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

