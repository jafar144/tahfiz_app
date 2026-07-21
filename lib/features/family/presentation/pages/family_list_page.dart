import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_cubit.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  @override
  void initState() {
    super.initState();
    context.read<FamilyCubit>().loadFamilies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(title: 'Manajemen Keluarga'),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushNamed(RouteNames.familyForm);
          if (context.mounted) context.read<FamilyCubit>().loadFamilies();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<FamilyCubit, FamilyState>(
        builder: (context, state) {
          final isLoading = state is FamilyLoading;
          List<FamilyWithMembers> families = [];

          if (state is FamilyLoaded) {
            families = state.families;
          }

          if (!isLoading && families.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data keluarga',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Skeletonizer(
            enabled: isLoading,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: isLoading ? 5 : families.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (isLoading) {
                  return _buildSkeletonCard();
                }

                final item = families[index];
                return _buildFamilyCard(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 150, height: 16, color: Colors.grey),
          const SizedBox(height: 8),
          Container(width: 200, height: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(BuildContext context, FamilyWithMembers item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await context.pushNamed(RouteNames.familyForm, extra: item);
            if (context.mounted) context.read<FamilyCubit>().loadFamilies();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.members.map((m) => m.name).join(', '),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.members.length} anggota',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
