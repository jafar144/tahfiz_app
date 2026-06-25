import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/santri_report_detail_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MonthlyReportListPage extends StatelessWidget {
  const MonthlyReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final userId = getIt<FirebaseAuth>().currentUser?.uid ?? '';
        return MonthlyReportCubit(
          reportRepository: getIt(),
          scheduleRepository: getIt(),
        )..loadData(userId);
      },
      child: const _MonthlyReportListView(),
    );
  }
}

class _MonthlyReportListView extends StatelessWidget {
  const _MonthlyReportListView();

  @override
  Widget build(BuildContext context) {
    final skeletonData = List.generate(5, (_) => SantriEntity.dummy());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(title: MonthlyReportStrings.penilaianBulanan),
      body: BlocBuilder<MonthlyReportCubit, MonthlyReportState>(
        builder: (context, state) {
          final isLoading = state is MonthlyReportLoading;

          if (state is MonthlyReportError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = getIt<FirebaseAuth>().currentUser?.uid ?? '';
                      context.read<MonthlyReportCubit>().loadData(userId);
                    },
                    child: const Text(MonthlyReportStrings.cobaLagi),
                  ),
                ],
              ),
            );
          }

          final MonthlyReportLoaded? loadedState =
              state is MonthlyReportLoaded ? state : null;

          final displayList = isLoading ? skeletonData : (loadedState?.santriList ?? []);

          return SafeArea(
            child: Column(
              children: [
                if (loadedState != null) _buildWindowInfo(loadedState),
                if (loadedState != null && loadedState.tertunggakTotal > 0)
                  _buildTertunggakBanner(loadedState.tertunggakTotal),
                Expanded(
                  child: displayList.isEmpty && !isLoading
                      ? _buildEmptyState()
                      : Skeletonizer(
                          enabled: isLoading,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayList.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final santri = displayList[index];
                              final isGraded = loadedState?.reportMap.containsKey(santri.id) ?? false;
                              final tertunggak =
                                  loadedState?.tertunggakBySantri[santri.id] ?? 0;

                              return _SantriReportCard(
                                santri: santri,
                                isGraded: isGraded,
                                tertunggakCount: tertunggak,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWindowInfo(MonthlyReportLoaded state) {
    final bulanStr = MonthlyReport.getNamaBulan(state.targetBulan);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: state.isInWindow ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state.isInWindow ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isInWindow ? Icons.edit_note_rounded : Icons.schedule_rounded,
            color: state.isInWindow ? Colors.green.shade700 : Colors.orange.shade700,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MonthlyReportStrings.periode(bulanStr, state.targetTahun),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: state.isInWindow
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.isInWindow
                      ? MonthlyReportStrings.penilaianTerbuka(state.daysRemaining)
                      : MonthlyReportStrings.menungguPeriode,
                  style: TextStyle(
                    fontSize: 12,
                    color: state.isInWindow
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTertunggakBanner(int total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              MonthlyReportStrings.tertunggakBanner(total),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            MonthlyReportStrings.listEmpty,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _SantriReportCard extends StatelessWidget {
  final SantriEntity santri;
  final bool isGraded;

  /// Jumlah penilaian bulan lampau yang belum diisi untuk santri ini.
  final int tertunggakCount;

  const _SantriReportCard({
    required this.santri,
    required this.isGraded,
    this.tertunggakCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasTertunggak = tertunggakCount > 0;

    // Tunggakan lebih mendesak, jadi border merah diprioritaskan.
    final Border? border = hasTertunggak
        ? Border.all(color: Colors.red.shade300, width: 2)
        : isGraded
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: border,
      ),
      child: SantriCard(
        santri,
        onTap: () => _onTap(context),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasTertunggak) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 13, color: Colors.red.shade600),
                    const SizedBox(width: 3),
                    Text(
                      MonthlyReportStrings.tertunggakBadge(tertunggakCount),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            isGraded
                ? Icon(Icons.check_circle,
                    color: Colors.green.shade400, size: 24)
                : Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final cubit = context.read<MonthlyReportCubit>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SantriReportDetailPage(santri: santri),
      ),
    ).then((_) {
      final userId = getIt<FirebaseAuth>().currentUser?.uid ?? '';
      cubit.loadData(userId);
    });
  }
}
