import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_detail_widgets.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
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
        extendBodyBehindAppBar: true,
        appBar: AiwaAppBar(
          title: 'Detail Asatidz',
          centerTitle: true,
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
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
              return FloatingActionButton.extended(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.editAsatidz,
                    extra: <String, dynamic>{
                      'asatidz': state.detail,
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

  Widget _buildContent(BuildContext context, AsatidzDetail detail) {
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: ${detail.nis}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const AiwaFormSectionTitle(title: 'Informasi Pribadi'),
                const SizedBox(height: 10),
                AiwaInfoCard(children: [
                  AiwaDetailInfoRow(
                    icon: detail.jenisKelamin == 'L' ? Icons.male : Icons.female,
                    label: 'Jenis Kelamin',
                    value: detail.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan',
                  ),
                  AiwaDetailInfoRow(
                    icon: Icons.phone,
                    label: 'No. Telepon',
                    value: detail.phone,
                  ),
                ]),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsatidzDetail detail) {
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
                  child: Text(
                    detail.name.isNotEmpty ? detail.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
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
}
