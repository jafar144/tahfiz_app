import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_state.dart';

class HalaqahDetailPage extends StatelessWidget {
  const HalaqahDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Halaqah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final cubit = context.read<HalaqahDetailCubit>();
              context.pushNamed(RouteNames.editHalaqah, extra: cubit);
            },
          ),
        ],
      ),
      body: BlocBuilder<HalaqahDetailCubit, HalaqahDetailState>(
        builder: (context, state) {
          if (state is HalaqahDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HalaqahDetailError) {
            return Center(child: Text(state.message));
          }
          if (state is HalaqahDetailLoaded) {
            final halaqah = state.halaqah;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(halaqah),
                  const SizedBox(height: 24),
                  _buildSantriList(halaqah),
                ],
              ),
            );
          }
          // Initial state
          if (state is HalaqahDetailInitial) {
             final halaqah = state.halaqah;
             return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildHeader(halaqah),
                  const SizedBox(height: 24),
                  _buildSantriList(halaqah),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildHeader(Halaqah halaqah) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            halaqah.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Pengajar: ${halaqah.teacherName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Status: ${halaqah.status}',
                style: TextStyle(
                  fontSize: 14,
                  color: halaqah.status == 'Active' ? Colors.green : Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSantriList(Halaqah halaqah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Santri (${halaqah.santris.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (halaqah.santris.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Belum ada santri di halaqah ini.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: halaqah.santris.length,
            itemBuilder: (context, index) {
              final santri = halaqah.santris[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      santri.name.isNotEmpty ? santri.name[0] : '?',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  title: Text(santri.name),
                  // subtitle: Text('ID: ${santri.id}'),
                ),
              );
            },
          ),
      ],
    );
  }
}
