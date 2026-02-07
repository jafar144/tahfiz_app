import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_state.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/student_payment_list_bottom_sheet.dart';

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
  
  void _showMonthYearPicker(BuildContext context, DateTime currentDate) {
    final now = DateTime.now();
    final years = List.generate(3, (index) => now.year - index);
    final months = List.generate(12, (index) => index + 1);

    int selectedYearIndex = years.indexOf(currentDate.year);
    if (selectedYearIndex == -1) selectedYearIndex = 0; // Fallback
    
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
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMonthIndex,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          selectedMonthIndex = index;
                        },
                        children: months.map((m) {
                          return Center(
                            child: Text(
                              DateFormat('MMMM', 'id_ID').format(DateTime(2024, m)),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Year Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedYearIndex,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          selectedYearIndex = index;
                        },
                        children: years.map((y) {
                          return Center(
                            child: Text(
                              y.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
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
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentError) {
            return Center(child: Text(state.message));
          }

          if (state is PaymentLoaded) {
            final displayDate = DateFormat('MMMM yyyy', 'id_ID').format(state.selectedDate);
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector
                    Center(
                      child: InkWell(
                        onTap: () => _showMonthYearPicker(context, state.selectedDate),
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
                            count: state.paidCount,
                            color: const Color(0xFF0CAF60), // Green
                            icon: Icons.check_circle_outline,
                            onTap: () => _showStudentList(
                              context, 
                              state.paidStudents, 
                              'Daftar Sudah Bayar',
                              state.selectedDate,
                              showWhatsApp: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Belum Bayar',
                            count: state.unpaidCount,
                            color: const Color(0xFFFD5D6F), // Red
                            icon: Icons.pending_actions_outlined,
                            onTap: () => _showStudentList(
                              context, 
                              state.unpaidStudents, 
                              'Daftar Belum Bayar',
                              state.selectedDate,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    // Transaction List
                    if (state.recentTransactions.isEmpty)
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
                        itemCount: state.recentTransactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = state.recentTransactions[index];
                          return _buildTransactionItem(item);
                        },
                      ),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
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

  Widget _buildTransactionItem(dynamic item) {
    // Handling dynamic item for PaymentEntity or mock map (since we switched to real data, it is PaymentEntity)
    // But let's check what state passes. It passes PaymentEntity.
    
    // Safety check just in case
    // ignore: avoid_dynamic_calls
    final name = (item.santriName) ?? 'Unknown';
    // ignore: avoid_dynamic_calls
    final amount = (item.total) ?? 0;
    // ignore: avoid_dynamic_calls
    final date = (item.createdAt) as DateTime;
    // ignore: avoid_dynamic_calls
    final month = (item.bulan) ?? 0;
    
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '+Rp ',
      decimalDigits: 0,
    );
    final timeStr = DateFormat('HH:mm').format(date);
    final dateStr = DateFormat('d MMM').format(date);
    final monthName = DateFormat('MMMM', 'id_ID').format(DateTime(2024, int.parse(month)));

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.orange.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'UR',
            style: const TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SPP $monthName • $timeStr',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency.format(amount),
              style: const TextStyle(
                color: Color(0xFF0CAF60),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
