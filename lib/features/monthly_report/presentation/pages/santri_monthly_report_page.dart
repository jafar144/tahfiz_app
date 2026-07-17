import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_monthly_report_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriMonthlyReportPage extends StatelessWidget {
  final String santriId;

  const SantriMonthlyReportPage({super.key, required this.santriId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SantriMonthlyReportCubit(repository: getIt())..loadReports(santriId),
      child: _SantriMonthlyReportView(santriId: santriId),
    );
  }
}

class _SantriMonthlyReportView extends StatelessWidget {
  final String santriId;

  const _SantriMonthlyReportView({required this.santriId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(title: MonthlyReportStrings.penilaianBulanan),
      body: BlocBuilder<SantriMonthlyReportCubit, SantriMonthlyReportState>(
        builder: (context, state) {
          if (state is SantriMonthlyReportLoading) {
            return _buildLoading();
          }

          if (state is SantriMonthlyReportError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SantriMonthlyReportCubit>()
                        .loadReports(santriId),
                    child: const Text(MonthlyReportStrings.cobaLagi),
                  ),
                ],
              ),
            );
          }

          if (state is SantriMonthlyReportLoaded) {
            if (state.reports.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => context
                  .read<SantriMonthlyReportCubit>()
                  .loadReports(santriId),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.reports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return MonthlyReportCard(report: state.reports[index]);
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            MonthlyReportStrings.belumAdaPenilaian,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            MonthlyReportStrings.santriEmptySubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
