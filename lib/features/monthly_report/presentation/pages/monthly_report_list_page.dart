import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/pages/monthly_report_input_page.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
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
      appBar: AiwaAppBar(title: 'Penilaian Bulanan'),
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
                    child: const Text('Coba Lagi'),
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
            
                              return _SantriReportCard(
                                santri: santri,
                                isGraded: isGraded,
                                isInWindow: loadedState?.isInWindow ?? false,
                                targetBulan: loadedState?.targetBulan ?? DateTime.now().month,
                                targetTahun: loadedState?.targetTahun ?? DateTime.now().year,
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
                  'Periode: $bulanStr ${state.targetTahun}',
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
                      ? 'Penilaian terbuka • ${state.daysRemaining} hari tersisa'
                      : 'Menunggu periode penilaian',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada santri di halaqah Anda',
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
  final bool isInWindow;
  final int targetBulan;
  final int targetTahun;

  const _SantriReportCard({
    required this.santri,
    required this.isGraded,
    required this.isInWindow,
    required this.targetBulan,
    required this.targetTahun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: isGraded
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
      ),
      child: SantriCard(
        santri,
        onTap: () => _onTap(context),
        trailing: isGraded
            ? Icon(Icons.check_circle, color: Colors.green.shade400, size: 24)
            : (isInWindow
                ? Icon(Icons.edit_rounded, color: Colors.blue.shade300, size: 20)
                : null),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (!isInWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penilaian hanya dapat diinput 1 minggu sebelum akhir bulan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => MonthlyReportInputCubit(repository: getIt())
            ..loadExisting(santri.id, targetBulan, targetTahun),
          child: MonthlyReportInputPage(
            santri: santri,
            asatidzId: authState.user.uid,
            asatidzName: authState.user.name,
            bulan: targetBulan,
            tahun: targetTahun,
          ),
        ),
      ),
    ).then((_) {
      final userId = getIt<FirebaseAuth>().currentUser?.uid ?? '';
      context.read<MonthlyReportCubit>().loadData(userId);
    });
  }
}
