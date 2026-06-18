import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_wheel_picker.dart';
import 'package:khoirunnasyien/features/financial_report/domain/entities/financial_report_data.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/cubit/financial_report_state.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/widgets/finance_kpi_card.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/widgets/finance_stat_card.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/widgets/revenue_breakdown_card.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/student_payment_list_bottom_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FinancialReportPage extends StatelessWidget {
  const FinancialReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FinancialReportCubit>()..loadReport(DateTime.now()),
      child: const FinancialReportView(),
    );
  }
}

class FinancialReportView extends StatelessWidget {
  const FinancialReportView({super.key});

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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        ctx.pop();
                        context.read<FinancialReportCubit>().loadReport(newDate);
                      },
                      child: const Text('Pilih',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AiwaWheelPicker<int>(
                        initialItem: selectedMonthIndex,
                        items: months,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) =>
                            selectedMonthIndex = index,
                        itemBuilder: (m) => Text(
                          DateFormat('MMMM', 'id_ID')
                              .format(DateTime(2024, m)),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: AiwaWheelPicker<int>(
                        initialItem: selectedYearIndex,
                        items: years,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) =>
                            selectedYearIndex = index,
                        itemBuilder: (y) => Text(
                          y.toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
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

  void _showUnpaidList(BuildContext context, FinancialReportData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, _) {
          return StudentPaymentListBottomSheet(
            title: 'Belum Bayar',
            students: data.unpaidStudents,
            monthYear:
                DateFormat('MMMM yyyy', 'id_ID').format(data.selectedDate),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const AiwaAppBar(title: 'Laporan Keuangan'),
      body: BlocBuilder<FinancialReportCubit, FinancialReportState>(
        builder: (context, state) {
          if (state is FinancialReportError) {
            return _buildError(context, state.message);
          }

          final isLoading =
              state is FinancialReportLoading || state is FinancialReportInitial;
          final data = state is FinancialReportLoaded
              ? state.data
              : _mockData();

          return Skeletonizer(
            enabled: isLoading,
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<FinancialReportCubit>().loadReport(
                        data.selectedDate,
                      ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(context, data.selectedDate, isLoading),
                    const SizedBox(height: 16),
                    FinanceKpiCard(data: data),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FinanceStatCard(
                            label: 'Sudah Bayar',
                            count: data.paidCount,
                            subtitle: 'termasuk gratis',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF0CAF60),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FinanceStatCard(
                            label: 'Belum Bayar',
                            count: data.unpaidCount,
                            subtitle: 'dari ${data.billableCount} wajib bayar',
                            icon: Icons.pending_actions_outlined,
                            color: const Color(0xFFFD5D6F),
                            onTap: isLoading
                                ? null
                                : () => _showUnpaidList(context, data),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RevenueBreakdownCard(data: data),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(
      BuildContext context, DateTime date, bool isLoading) {
    final label = DateFormat('MMMM yyyy', 'id_ID').format(date);
    return Center(
      child: InkWell(
        onTap: isLoading ? null : () => _showMonthYearPicker(context, date),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                label,
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
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<FinancialReportCubit>()
                  .loadReport(DateTime.now()),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Data tiruan untuk efek skeleton saat memuat.
  FinancialReportData _mockData() {
    final now = DateTime.now();
    return FinancialReportData(
      selectedDate: now,
      totalRevenue: 15000000,
      previousMonthRevenue: 12000000,
      transactionCount: 120,
      billableCount: 150,
      paidCount: 120,
      unpaidStudents: const [],
      groups: const [
        RevenueGroup(
            label: 'Putra Sore',
            gender: 'L',
            session: 'Sore',
            revenue: 10000000,
            paymentCount: 80),
        RevenueGroup(
            label: 'Putri Pagi',
            gender: 'P',
            session: 'Pagi',
            revenue: 5000000,
            paymentCount: 40),
      ],
    );
  }
}
