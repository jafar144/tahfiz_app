import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_santri_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AsatidzSantriPage extends StatelessWidget {
  const AsatidzSantriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final userId = getIt<FirebaseAuth>().currentUser?.uid ?? '';
        return getIt<AsatidzSantriCubit>()..loadMySantri(userId);
      },
      child: const _AsatidzSantriView(),
    );
  }
}

class _AsatidzSantriView extends StatelessWidget {
  const _AsatidzSantriView();

  @override
  Widget build(BuildContext context) {
    // Skeleton data for loading state
    final List<SantriEntity> skeletonData = List.generate(
      5,
      (index) => SantriEntity(
        id: 'skeleton',
        name: 'Nama Santri Placeholder',
        nis: '12345',
        kelas: 'Tahfiz 1',
        jenisKelamin: 'L',
        isActive: true,
        isFree: false,
        nomorWali: '0812...',
        pembimbing: 'Ustadz Fulan',
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(title: "Santri Saya"),
      body: BlocBuilder<AsatidzSantriCubit, AsatidzSantriState>(
        builder: (context, state) {
          final isLoading = state is AsatidzSantriLoading;
          final List<SantriEntity> displayList;

          if (isLoading) {
            displayList = skeletonData;
          } else if (state is AsatidzSantriLoaded) {
            displayList = state.santri;
          } else {
            displayList = [];
          }

          if (state is AsatidzSantriLoaded && state.santri.isEmpty) {
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

          if (state is AsatidzSantriError) {
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
                      context.read<AsatidzSantriCubit>().loadMySantri(userId);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return Skeletonizer(
            enabled: isLoading,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return SantriCard(
                  displayList[index],
                  extra: const {'readOnly': true},
                  onReturn: () {
                     // Refresh data when returning from detail page
                     final userId = getIt<FirebaseAuth>().currentUser?.uid ?? '';
                     context.read<AsatidzSantriCubit>().loadMySantri(userId);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
