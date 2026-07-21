import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/santri/presentation/widgets/santri_setoran_card.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_chip.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_setoran_cubit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriSetoranPage extends StatelessWidget {
  const SantriSetoranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const AiwaAppBar(title: 'Riwayat Setoran'),
      body: Column(
        children: [
          _buildFilterSection(context),
          Expanded(child: _buildListSection()),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return BlocBuilder<SantriSetoranCubit, SantriSetoranState>(
      buildWhen: (previous, current) => previous.filter != current.filter,
      builder: (context, state) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AiwaChip(
                label: _getFilterLabel(state.filter),
                isSelected: true,
                onTap: () {
                  _showFilterBottomSheet(context, state.filter);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFilterLabel(SetoranFilter filter) {
    switch (filter) {
      case SetoranFilter.bulanIni:
        return 'Bulan Ini';
      case SetoranFilter.tigaBulan:
        return '3 Bulan Terakhir';
      case SetoranFilter.enamBulan:
        return '6 Bulan Terakhir';
      case SetoranFilter.semua:
        return 'Semua';
    }
  }

  void _showFilterBottomSheet(
    BuildContext context,
    SetoranFilter currentFilter,
  ) {
    final cubit = context.read<SantriSetoranCubit>();
    SetoranFilter selectedFilter = currentFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (childContext, setState) {
          return AiwaBottomSheet(
            title: 'Filter Waktu',
            onReset: () {
              setState(() {
                selectedFilter = SetoranFilter.bulanIni;
              });
            },
            onApply: () {
              Navigator.pop(childContext);
              cubit.loadSetoran(filter: selectedFilter);
            },
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SetoranFilter.values.map((filter) {
                final isSelected = filter == selectedFilter;
                return ChoiceChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedFilter = filter;
                      }
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListSection() {
    return BlocBuilder<SantriSetoranCubit, SantriSetoranState>(
      builder: (context, state) {
        if (state.status == SantriSetoranStatus.loading) {
          return _buildSkeletonList();
        }

        if (state.status == SantriSetoranStatus.failure &&
            state.setoranList.isEmpty) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        if (state.setoranList.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<SantriSetoranCubit>().loadSetoran();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: Colors.blue.shade300,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Belum ada riwayat setoran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Setoran hafalan akan muncul di sini',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await context.read<SantriSetoranCubit>().loadSetoran();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.setoranList.length,
            itemBuilder: (context, index) {
              final setoran = state.setoranList[index];
              return _buildSetoranCard(setoran);
            },
          ),
        );
      },
    );
  }

  Widget _buildSetoranCard(SantriSetoran setoran) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SantriSetoranCard(setoran: setoran),
    );
  }

  Widget _buildSkeletonList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 14,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 90,
                            height: 12,
                            color: Colors.grey.shade200,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
