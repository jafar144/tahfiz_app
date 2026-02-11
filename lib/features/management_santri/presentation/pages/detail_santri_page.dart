import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/pages/santri_deposit_history_page.dart';

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
    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Detail Santri', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.blue.shade600,
          elevation: 0,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: ${detail.nis}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildLastSetoranSection(detail),
                const SizedBox(height: 20),
                // _buildAttendanceSection(),
                // const SizedBox(height: 20),
                _buildSectionTitle('Informasi Akademik'),
                const SizedBox(height: 10),
                _buildInfoCard([
                  _buildInfoRow(Icons.class_, 'Kelas', detail.kelas),
                  _buildInfoRow(Icons.category, 'Tipe Kelas', detail.tipeKelas ?? '-'),
                  _buildInfoRow(Icons.supervisor_account, 'Pembimbing', detail.pembimbing ?? '-'),
                  _buildInfoRow(Icons.payments, 'Status Biaya', detail.isFree ? 'Gratis' : 'Reguler'),
                  _buildInfoRow(Icons.calendar_today, 'Tanggal Masuk',
                      detail.tanggalMasuk != null
                          ? DateFormat('dd MMMM yyyy', 'id').format(detail.tanggalMasuk!)
                          : '-'),
                ]),
                const SizedBox(height: 20),
                _buildSectionTitle('Informasi Pribadi'),
                const SizedBox(height: 10),
                _buildInfoCard([
                  _buildInfoRow(Icons.location_on, 'Tempat Lahir', detail.tempatLahir ?? '-'),
                  _buildInfoRow(Icons.cake, 'Tanggal Lahir',
                      detail.tanggalLahir != null
                          ? DateFormat('dd MMMM yyyy', 'id').format(detail.tanggalLahir!)
                          : '-'),
                  _buildInfoRow(
                    detail.jenisKelamin == 'L' ? Icons.male : Icons.female,
                    'Jenis Kelamin',
                    detail.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan',
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionTitle('Informasi Wali'),
                const SizedBox(height: 10),
                _buildInfoCard([
                  _buildInfoRow(Icons.person, 'Nama Wali', detail.namaWali ?? '-'),
                  _buildInfoRow(Icons.phone, 'Nomor HP Wali', detail.nomorWali ?? '-'),
                ]),
                const SizedBox(height: 80), // Specs for FAB
              ],
            ),
          ),
        ],
      ),
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    detail.name.isNotEmpty ? detail.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLastSetoranSection(SantriDetail detail) {
    return FutureBuilder(
      future: getIt<AsatidzRepository>().getSetoranHistory(santriId: detail.id),
      builder: (context, snapshot) {
        SantriSetoran? lastSetoran;
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (snapshot.hasData) {
          snapshot.data!.fold(
            ifLeft: (_) {},
            ifRight: (history) {
              if (history.isNotEmpty) {
                history.sort((a, b) => b.date.compareTo(a.date));
                lastSetoran = history.first;
              }
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.menu_book, color: Colors.blue.shade800),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Hafalan Terakhir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SantriDepositHistoryPage(
                              santriId: detail.id,
                              santriName: detail.name,
                            ),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : lastSetoran != null
                        ? Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lastSetoran!.surah,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMMM yyyy HH:mm', 'id').format(lastSetoran!.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (lastSetoran!.catatan.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Text(
                                          'Catatan: ${lastSetoran!.catatan}',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ],
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Belum ada data hafalan',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSection() {
    // Dummy Data for Preview
    const int hadir = 22;
    const int sakit = 1;
    const int izin = 2;
    const int alpha = 0;
    const String todayStatus = "Hadir";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.access_time_filled, color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Kehadiran Bulan Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Attendance History Page
                  },
                  child: const Text('Lihat Riwayat'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.green.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Hari Ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              todayStatus,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStatItem('Hadir', hadir.toString(), Colors.green),
                    _buildAttendanceStatItem('Sakit', sakit.toString(), Colors.orange),
                    _buildAttendanceStatItem('Izin', izin.toString(), Colors.blue),
                    _buildAttendanceStatItem('Alpha', alpha.toString(), Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
