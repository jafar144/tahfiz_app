import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/halaqah_deposit_list_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_setoran_page.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_deposit_history_page.dart';

class HalaqahDepositListPage extends StatelessWidget {
  final ActiveHalaqah activeHalaqah;

  const HalaqahDepositListPage({
    super.key,
    required this.activeHalaqah,
  });

  @override
  Widget build(BuildContext context) {
    // Capture dependencies to pass to Cubit
    final dashboardCubit = context.read<AsatidzDashboardCubit>();
    
    return BlocProvider(
      create: (context) => HalaqahDepositListCubit(
        repository: dashboardCubit.asatidzRepository,
        activeHalaqah: activeHalaqah,
      )..loadData(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AiwaAppBar(title: "Setoran Santri"),
        body: SafeArea(
          child: BlocBuilder<HalaqahDepositListCubit, HalaqahDepositListState>(
            builder: (context, state) {
              if (state is HalaqahDepositListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
          
              if (state is HalaqahDepositListError) {
                return Center(child: Text('Error: ${state.message}'));
              }
          
              if (state is HalaqahDepositListLoaded) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.summaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final summary = state.summaries[index];
                    return _buildSantriCard(context, summary, dashboardCubit.asatidzId);
                  },
                );
              }
          
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSantriCard(BuildContext context, SantriDepositSummary summary, String asatidzId) {
    bool hasTodayDeposit = summary.todayDeposit != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final dashboardCubit = context.read<AsatidzDashboardCubit>();
            
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => SantriSetoranCubit(
                    repository: dashboardCubit.asatidzRepository,
                    activeHalaqah: activeHalaqah,
                    santri: summary.santri,
                    asatidzId: asatidzId,
                    asatidzName: activeHalaqah.halaqah.teacherName,
                  )..loadInitialData(),
                  child: SantriSetoranPage(
                    activeHalaqah: activeHalaqah,
                    santri: summary.santri,
                  ),
                ),
              ),
            );
            // Reload data after return
            if (context.mounted) {
              context.read<HalaqahDepositListCubit>().loadData();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(context, summary.santri),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDepositInfo(
                        label: 'LAST DEPOSIT',
                        setoran: summary.lastDeposit,
                        isToday: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDepositInfo(
                        label: "TODAY'S DEPOSIT",
                        setoran: summary.todayDeposit,
                        isToday: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hasTodayDeposit ? Colors.grey.shade200 : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasTodayDeposit ? Icons.edit : Icons.add_circle,
                        color: hasTodayDeposit ? Colors.grey.shade700 : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasTodayDeposit ? 'Edit Setoran' : 'Input Setoran',
                        style: TextStyle(
                          color: hasTodayDeposit ? Colors.grey.shade700 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, HalaqahSantri santri) {
    final initial = santri.name.isNotEmpty ? santri.name[0].toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade50,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                santri.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'NIS: ${santri.nis}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SantriDepositHistoryPage(
                  santriId: santri.id,
                  santriName: santri.name,
                ),
              ),
            );
          },
          icon: const Icon(Icons.history, color: Colors.blue),
          tooltip: 'Lihat History',
        ),
      ],
    );
  }

  Widget _buildDepositInfo({
    required String label,
    required SantriSetoran? setoran,
    required bool isToday,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.blue.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.blue.shade700 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          if (setoran != null) ...[
            Text(
              setoran.surah,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.blue.shade900 : Colors.black87,
              ),
            ),
            if (setoran.catatan.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${setoran.catatan}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ] else
            Text(
              '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }
}
