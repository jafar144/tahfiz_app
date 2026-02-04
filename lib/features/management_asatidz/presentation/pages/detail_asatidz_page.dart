import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_state.dart';

class DetailAsatidzPage extends StatefulWidget {
  final String asatidzId;

  const DetailAsatidzPage({super.key, required this.asatidzId});

  @override
  State<DetailAsatidzPage> createState() => _DetailAsatidzPageState();
}

class _DetailAsatidzPageState extends State<DetailAsatidzPage> {
  late AsatidzDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AsatidzDetailCubit>()..loadDetail(widget.asatidzId);
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
        appBar: AppBar(
          title: const Text('Detail Asatidz'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<AsatidzDetailCubit, AsatidzDetailState>(
          builder: (context, state) {
            if (state is AsatidzDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AsatidzDetailError) {
              return Center(child: Text(state.message));
            } else if (state is AsatidzDetailLoaded) {
              return _buildContent(context, state.detail);
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: BlocBuilder<AsatidzDetailCubit, AsatidzDetailState>(
          builder: (context, state) {
            if (state is AsatidzDetailLoaded) {
              return FloatingActionButton(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.editAsatidz,
                    extra: <String, dynamic>{
                      'asatidz': state.detail,
                      'cubit': _cubit,
                    },
                  );
                },
                child: const Icon(Icons.edit),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AsatidzDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: detail.jenisKelamin == 'L'
                      ? Colors.blue.shade100
                      : Colors.pink.shade100,
                  child: Icon(
                    detail.jenisKelamin == 'L' ? Icons.face : Icons.face_3,
                    color:
                        detail.jenisKelamin == 'L' ? Colors.blue : Colors.pink,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: ${detail.nis}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: detail.isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          detail.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: detail.isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection('Informasi Pribadi', [
            _buildInfoRow(
                'Jenis Kelamin',
                detail.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'),
            _buildInfoRow('No. Telepon', detail.phone),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
