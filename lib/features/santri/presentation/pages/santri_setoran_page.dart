
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(
        title: const Text('Riwayat Setoran'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildFilterSection(context),
          Expanded(
            child: _buildListSection(),
          ),
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

  void _showFilterBottomSheet(BuildContext context, SetoranFilter currentFilter) {
    SetoranFilter selectedFilter = currentFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setState) {
          return AiwaBottomSheet(
            title: 'Filter Waktu',
            onReset: () {
               setState(() {
                 selectedFilter = SetoranFilter.bulanIni;
               });
            },
            onApply: () {
               Navigator.pop(context);
               // Use the context from the page (SantriSetoranPage), not the sheet's context
               context.read<SantriSetoranCubit>().loadSetoran(filter: selectedFilter);
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

        if (state.status == SantriSetoranStatus.failure && state.setoranList.isEmpty) {
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
                height: MediaQuery.of(context).size.height * 0.7, // Ensure scroll area
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat setoran',
                        style: TextStyle(color: Colors.grey.shade500),
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
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05), // Softer shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setoran.surah,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disimak oleh: ${setoran.asatidzName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        dateFormat.format(setoran.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (setoran.catatan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Pengajar:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      setoran.catatan,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              // leading: const CircleAvatar(child: Icon(Icons.menu_book)),
              title: const Text('Surah Al-Mulk'),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Disimak oleh: Ustadz Fulan'),
                  SizedBox(height: 4),
                  Text('12 Feb 2024'),
                ],
              ),
              /*
              trailing: Container(
                width: 60,
                height: 24,
                color: Colors.grey,
              ),
              */
            ),
          );
        },
      ),
    );
  }
}
