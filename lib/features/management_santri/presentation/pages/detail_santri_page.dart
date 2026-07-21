import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_detail_widgets.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/switch_pembimbing_sheet.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_state.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_year_view.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriDetailPage extends StatefulWidget {
  final String santriId;
  final bool readOnly;

  const SantriDetailPage({
    super.key,
    required this.santriId,
    this.readOnly = false,
  });

  @override
  State<SantriDetailPage> createState() => _SantriDetailPageState();
}

class _SantriDetailPageState extends State<SantriDetailPage> {
  late SantriDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SantriDetailCubit>()..loadDetail(widget.santriId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _cubit),
        BlocProvider(
          create: (_) =>
              getIt<SantriPaymentHistoryCubit>()..loadHistory(widget.santriId),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        appBar: AiwaAppBar(
          title: 'Detail Santri',
          centerTitle: true,
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<SantriDetailCubit, SantriDetailState>(
          builder: (context, state) {
            if (state is SantriDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SantriDetailError) {
              return Center(child: Text(state.message));
            } else if (state is SantriDetailLoaded) {
              return _buildContent(context, state.detail);
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: BlocBuilder<SantriDetailCubit, SantriDetailState>(
          builder: (context, state) {
            if (state is SantriDetailLoaded && !widget.readOnly) {
              return FloatingActionButton.extended(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.editSantri,
                    extra: <String, dynamic>{
                      'santri': state.detail,
                      'cubit': _cubit,
                    },
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profil'),
                backgroundColor: Colors.blue.shade600,
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SantriDetail detail) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(detail),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Text(
                        detail.name,
                        style: const TextStyle(
                          fontSize: 20, // Reduced from 22
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: ${detail.nis}',
                        style: TextStyle(
                          fontSize: 13, // Reduced from 14
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!detail.isActive) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Tidak Aktif',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AiwaFormSectionTitle(title: 'Informasi Akademik'),
                const SizedBox(height: 10),
                AiwaInfoCard(
                  children: [
                    AiwaDetailInfoRow(
                      icon: Icons.class_,
                      label: 'Kelas',
                      value: detail.kelas,
                    ),
                    if (detail.kelasFiqih != null)
                      AiwaDetailInfoRow(
                        icon: Icons.menu_book_outlined,
                        label: 'Kelas Fiqih',
                        value: detail.kelasFiqih!,
                      ),
                    AiwaDetailInfoRow(
                      icon: Icons.category,
                      label: 'Tipe Kelas',
                      value: detail.tipeKelas ?? '-',
                    ),
                    AiwaDetailInfoRow(
                      icon: Icons.payments,
                      label: 'Status Biaya',
                      value: detail.isFree
                          ? 'Gratis (Sampai ${detail.freeUntil != null ? DateFormat('d MMM yyyy').format(detail.freeUntil!) : '-'})'
                          : 'Reguler',
                    ),
                    AiwaDetailInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Tanggal Masuk',
                      value: detail.tanggalMasuk != null
                          ? DateFormat(
                              'dd MMMM yyyy',
                              'id',
                            ).format(detail.tanggalMasuk!)
                          : '-',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const AiwaFormSectionTitle(title: 'Pembimbing'),
                const SizedBox(height: 10),
                _buildPembimbingSection(detail),
                const SizedBox(height: 20),
                const AiwaFormSectionTitle(title: 'Informasi Pribadi'),
                const SizedBox(height: 10),
                AiwaInfoCard(
                  children: [
                    AiwaDetailInfoRow(
                      icon: Icons.location_on,
                      label: 'Tempat Lahir',
                      value: detail.tempatLahir ?? '-',
                    ),
                    AiwaDetailInfoRow(
                      icon: Icons.cake,
                      label: 'Tanggal Lahir',
                      value: detail.tanggalLahir != null
                          ? DateFormat(
                              'dd MMMM yyyy',
                              'id',
                            ).format(detail.tanggalLahir!)
                          : '-',
                    ),
                    AiwaDetailInfoRow(
                      icon: detail.jenisKelamin == 'L'
                          ? Icons.male
                          : Icons.female,
                      label: 'Jenis Kelamin',
                      value: detail.jenisKelamin == 'L'
                          ? 'Laki-laki'
                          : 'Perempuan',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const AiwaFormSectionTitle(title: 'Informasi Wali'),
                const SizedBox(height: 10),
                AiwaInfoCard(
                  children: [
                    AiwaDetailInfoRow(
                      icon: Icons.person,
                      label: 'Nama Wali',
                      value: detail.namaWali ?? '-',
                    ),
                    AiwaDetailInfoRow(
                      icon: Icons.phone,
                      label: 'Nomor HP Wali',
                      value: detail.nomorWali ?? '-',
                    ),
                  ],
                ),
                // Penilaian bulanan hanya ditampilkan untuk admin.
                if (_isAdmin) ...[
                  const SizedBox(height: 20),
                  _buildLatestReport(detail),
                ],
                const SizedBox(height: 20),
                const AiwaFormSectionTitle(title: 'Riwayat Pembayaran'),
                const SizedBox(height: 10),
                _buildPaymentSection(detail),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hanya admin yang boleh melihat penilaian bulanan santri di halaman ini.
  bool get _isAdmin {
    final authState = context.read<AuthCubit>().state;
    return authState is AuthAuthenticated &&
        authState.user.role == UserRole.admin;
  }

  /// Penilaian bulanan terbaru + tombol "Lihat Semua" ke riwayat lengkap.
  Widget _buildLatestReport(SantriDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AiwaFormSectionTitle(title: 'Penilaian Bulanan'),
            TextButton(
              onPressed: () => _openAllReports(detail),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder(
          future: getIt<MonthlyReportRepository>().getLatestReportBySantri(
            detail.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Skeletonizer(
                enabled: true,
                child: MonthlyReportCard(report: MonthlyReport.dummy()),
              );
            }

            MonthlyReport? latest;
            snapshot.data?.fold(
              ifLeft: (_) {},
              ifRight: (report) => latest = report,
            );

            if (latest == null) {
              return _buildEmptyReportCard();
            }
            return MonthlyReportCard(report: latest!);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada penilaian',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Buka halaman riwayat penilaian lengkap milik santri ini.
  void _openAllReports(SantriDetail detail) {
    context.pushNamed(
      RouteNames.santriReportDetail,
      extra: <String, dynamic>{
        'santri': _toSantriEntity(detail),
        'viewOnly': true,
      },
    );
  }

  /// SantriReportDetailPage butuh [SantriEntity]; kita punya [SantriDetail].
  SantriEntity _toSantriEntity(SantriDetail detail) {
    return SantriEntity(
      id: detail.id,
      name: detail.name,
      nis: detail.nis,
      kelas: detail.kelas,
      kelasFiqih: detail.kelasFiqih,
      jenisKelamin: detail.jenisKelamin,
      isActive: detail.isActive,
      isFree: detail.isFree,
      freeUntil: detail.freeUntil,
      tanggalMasuk: detail.tanggalMasuk,
      pembimbing: detail.pembimbing,
      nomorWali: detail.nomorWali,
      tipeKelas: detail.tipeKelas,
      halaqahId: detail.halaqahId,
      halaqahName: detail.halaqahName,
      photoUrl: detail.photoUrl,
    );
  }

  /// Section pembimbing dengan tombol untuk memindahkan santri ke pembimbing
  /// lain (lewat halaqah). Tombol disembunyikan pada mode readOnly.
  Widget _buildPembimbingSection(SantriDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.supervisor_account,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembimbing',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.pembimbing ?? 'Belum ada',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.readOnly)
            IconButton(
              onPressed: () => _openSwitchPembimbing(detail),
              icon: Icon(Icons.swap_horiz_rounded, color: Colors.blue.shade700),
              tooltip: 'Ganti Pembimbing',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSwitchPembimbing(SantriDetail detail) async {
    final moved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwitchPembimbingSheet(
        santriId: detail.id,
        santriName: detail.name,
        santriGender: detail.jenisKelamin,
      ),
    );
    if (moved == true && mounted) {
      _cubit.loadDetail(widget.santriId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembimbing berhasil diganti')),
      );
    }
  }

  Widget _buildFreePaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bebas SPP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Santri ini gratis, tidak ada tagihan SPP',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(SantriDetail detail) {
    if (detail.isFree) {
      return _buildFreePaymentCard();
    }

    return BlocBuilder<SantriPaymentHistoryCubit, SantriPaymentHistoryState>(
      builder: (context, state) {
        if (state is SantriPaymentHistoryLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SantriPaymentHistoryError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Gagal memuat riwayat pembayaran',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          );
        }

        if (state is SantriPaymentHistoryLoaded) {
          final paidData = <int, Set<int>>{};
          for (final p in state.payments) {
            final year = int.tryParse(p.tahun);
            final month = int.tryParse(p.bulan);
            if (year != null && month != null) {
              paidData.putIfAbsent(year, () => {}).add(month);
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: PaymentYearView(
              paidData: paidData,
              startDate: PaymentUtils.resolveStartDate(
                freeUntil: detail.freeUntil,
                tanggalMasuk: detail.tanggalMasuk,
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(SantriDetail detail) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      detail.photoUrl != null && detail.photoUrl!.isNotEmpty
                      ? NetworkImage(detail.photoUrl!)
                      : null,
                  child: detail.photoUrl == null || detail.photoUrl!.isEmpty
                      ? Text(
                          detail.name.isNotEmpty
                              ? detail.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
