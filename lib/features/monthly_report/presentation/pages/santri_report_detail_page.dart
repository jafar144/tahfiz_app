import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_report_detail_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_report_detail_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/missing_report_card.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriReportDetailPage extends StatelessWidget {
  final SantriEntity santri;

  /// Mode lihat-saja: sembunyikan tombol tambah/edit penilaian. Dipakai saat
  /// halaman dibuka dari detail santri (admin hanya melihat riwayat).
  final bool viewOnly;

  const SantriReportDetailPage({
    super.key,
    required this.santri,
    this.viewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SantriReportDetailCubit(repository: getIt())
            ..load(santri.id, joinedAt: santri.tanggalMasuk),
      child: _SantriReportDetailView(santri: santri, viewOnly: viewOnly),
    );
  }
}

class _SantriReportDetailView extends StatefulWidget {
  final SantriEntity santri;
  final bool viewOnly;

  const _SantriReportDetailView({required this.santri, this.viewOnly = false});

  @override
  State<_SantriReportDetailView> createState() =>
      _SantriReportDetailViewState();
}

class _SantriReportDetailViewState extends State<_SantriReportDetailView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<SantriReportDetailCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(title: MonthlyReportStrings.riwayatPenilaian),
      // Mode lihat-saja (mis. dibuka dari detail santri) tak punya tombol tambah.
      floatingActionButton: widget.viewOnly
          ? null
          : BlocBuilder<SantriReportDetailCubit, SantriReportDetailState>(
              builder: (context, state) {
                final isEdit =
                    state is SantriReportDetailLoaded &&
                    state.currentMonthFilled;
                return FloatingActionButton.extended(
                  onPressed: _onAddPressed,
                  icon: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded),
                  label: Text(
                    isEdit
                        ? MonthlyReportStrings.editPenilaian
                        : MonthlyReportStrings.tambahPenilaian,
                  ),
                );
              },
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Header santri "fixed" di paling atas.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SantriCard(widget.santri, onTap: () {}),
            ),
            BlocBuilder<SantriReportDetailCubit, SantriReportDetailState>(
              builder: (context, state) {
                final currentTarget = state is SantriReportDetailLoaded
                    ? state.currentMonthTarget
                    : null;
                if (currentTarget == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CurrentMonthlyTargetCard(progress: currentTarget),
                );
              },
            ),
            Expanded(
              child:
                  BlocBuilder<SantriReportDetailCubit, SantriReportDetailState>(
                    builder: (context, state) {
                      if (state is SantriReportDetailLoading) {
                        return _buildSkeleton();
                      }

                      if (state is SantriReportDetailError) {
                        return _buildError(state.message);
                      }

                      if (state is SantriReportDetailLoaded) {
                        if (state.reports.isEmpty &&
                            state.missingPeriods.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildList(state);
                      }

                      return const SizedBox();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(SantriReportDetailLoaded state) {
    final missing = state.missingPeriods;
    // Seksi tertunggak (header + kartu merah) ditaruh di paling atas.
    final missingItemCount = missing.isEmpty ? 0 : missing.length + 1;
    final showFooter = state.isLoadingMore;
    final itemCount =
        missingItemCount + state.reports.length + (showFooter ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      // Ruang ekstra di bawah agar item terakhir tidak tertutup FAB.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // 1) Seksi tertunggak: header lalu daftar kartu merah.
        if (missingItemCount > 0 && index < missingItemCount) {
          if (index == 0) {
            return const _SectionHeader(
              MonthlyReportStrings.penilaianTertunggak,
            );
          }
          final period = missing[index - 1];
          return MissingReportCard(
            bulan: period.bulan,
            tahun: period.tahun,
            onTap: () => _openInput(period.bulan, period.tahun),
          );
        }

        // 2) Daftar riwayat (paginasi) + footer skeleton saat memuat lagi.
        final reportIndex = index - missingItemCount;
        if (reportIndex >= state.reports.length) {
          return Skeletonizer(
            enabled: true,
            child: MonthlyReportCard(report: MonthlyReport.dummy()),
          );
        }
        final report = state.reports[reportIndex];
        return MonthlyReportCard(
          report: report,
          periodTarget: state.periodTargetsByReportId[report.id],
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => MonthlyReportCard(report: MonthlyReport.dummy()),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<SantriReportDetailCubit>().load(
              widget.santri.id,
              joinedAt: widget.santri.tanggalMasuk,
            ),
            child: const Text(MonthlyReportStrings.cobaLagi),
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
            MonthlyReportStrings.detailEmptySubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  /// FAB "Tambah Penilaian": bulan berjalan, tunduk pada window penilaian.
  void _onAddPressed() {
    final now = DateTime.now();

    if (!MonthlyReportCubit.checkIsInWindow(now)) {
      _showWindowClosedDialog();
      return;
    }

    _openInput(
      MonthlyReportCubit.getTargetBulan(now),
      MonthlyReportCubit.getTargetTahun(now),
    );
  }

  /// Buka halaman input untuk periode tertentu. Dipakai oleh FAB (bulan
  /// berjalan) maupun kartu tertunggak (bulan lampau, tanpa cek window).
  void _openInput(int bulan, int tahun) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final detailCubit = context.read<SantriReportDetailCubit>();

    context
        .pushNamed(
          RouteNames.monthlyReportInput,
          extra: <String, dynamic>{
            'santri': widget.santri,
            'asatidzId': authState.user.uid,
            'asatidzName': authState.user.name,
            'bulan': bulan,
            'tahun': tahun,
          },
        )
        .then(
          (_) => detailCubit.load(
            widget.santri.id,
            joinedAt: widget.santri.tanggalMasuk,
          ),
        );
  }

  void _showWindowClosedDialog() {
    showAiwaActionSheet<void>(
      context: context,
      title: MonthlyReportStrings.windowClosedTitle,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, color: Colors.orange.shade600, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              MonthlyReportStrings.windowClosedMessage,
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
      confirmText: MonthlyReportStrings.mengerti,
      showCancelAction: false,
    );
  }
}

/// Judul kecil pemisah antar-seksi di dalam daftar.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}
