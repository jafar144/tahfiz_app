import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';

class SelectSantriPage extends StatefulWidget {
  final String? genderFiltered;
  final List<SantriEntity> initialSelection;
  final List<String> disabledIds;
  final bool isMultiSelect;

  /// Bila diisi, daftar santri dibatasi hanya pada halaqah milik asatidz ini
  /// (termasuk saat pencarian). Dipakai mis. oleh fitur kelulusan untuk
  /// asatidz. Bila null, menampilkan seluruh santri (perilaku admin).
  final String? asatidzId;

  /// Filter berdasarkan status pembayaran: true=Gratis, false=Reguler.
  /// Bila null, menampilkan keduanya. Dipakai mis. oleh fitur pembayaran
  /// untuk hanya menampilkan santri reguler.
  final bool? isFree;

  const SelectSantriPage({
    super.key,
    this.genderFiltered,
    this.initialSelection = const [],
    this.disabledIds = const [],
    this.isMultiSelect = false,
    this.asatidzId,
    this.isFree,
  });

  @override
  State<SelectSantriPage> createState() => _SelectSantriPageState();
}

class _SelectSantriPageState extends State<SelectSantriPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SantriEntity> _selectedSantri = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedSantri = List.from(widget.initialSelection);
    _scrollController.addListener(_onScroll);
    
    // Paksa load santri yang aktif saja ketika halaman ini dibuka
    context.read<SantriCubit>().loadSantri(
      isActive: true,
      gender: widget.genderFiltered,
      asatidzId: widget.asatidzId,
      isFree: widget.isFree,
      keyword: '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SantriCubit>().loadMoreSantri();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearch() {
    context.read<SantriCubit>().loadSantri(
      isActive: true,
      gender: widget.genderFiltered,
      asatidzId: widget.asatidzId,
      isFree: widget.isFree,
      keyword: _searchController.text,
    );
  }

  void _toggleSelection(SantriEntity santri) {
    setState(() {
      if (_selectedSantri.any((s) => s.id == santri.id)) {
        _selectedSantri.removeWhere((s) => s.id == santri.id);
      } else {
        _selectedSantri.add(santri);
      }
    });
  }

  void _submit() {
    context.pop(_selectedSantri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(title: 'Pilih Santri'),
      bottomNavigationBar: widget.isMultiSelect
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AiwaButton(
                text: 'Pilih (${_selectedSantri.length})',
                onPressed: _submit,
              ),
            ),
          )
        : null,
      body: BlocBuilder<SantriCubit, SantriState>(
        builder: (context, state) {
          // Determine list to show
          List<SantriEntity> santriList = [];
          if (state is SantriLoaded) {
            santriList = state.santri;
          }

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AiwaSearch(
                    controller: _searchController,
                    onSubmitted: (_) => _onSearch(),
                    onSearch: _onSearch,
                    hintText: 'Cari Santri...',
                  ),
                ),
                Expanded(
                  child: Skeletonizer(
                    enabled: state is SantriLoading,
                    child: santriList.isEmpty && state is! SantriLoading
                        ? const Center(
                            child: Text(
                              'Data santri tidak ditemukan',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: state is SantriLoading ? 10 : santriList.length + (state is SantriLoaded && !state.hasReachedMax ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              // Show spinner at bottom when fetching more (or if there is more data to load)
                              if (state is! SantriLoading && index >= santriList.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Skeletonizer(
                                    enabled: true,
                                    child: SantriCard(SantriEntity.dummy()),
                                  ),
                                );
                              }

                              final santri = (state is SantriLoading || santriList.isEmpty)
                                  ? SantriEntity.dummy()
                                  : santriList[index];

                              final isSelected = _selectedSantri.any((s) => s.id == santri.id);
                              final isDisabled = widget.disabledIds.contains(santri.id);

                              return Opacity(
                                opacity: isDisabled ? 0.5 : 1.0,
                                child: SantriCard(
                                  santri,
                                  trailing: widget.isMultiSelect 
                                    ? Checkbox(
                                        value: isSelected, 
                                        onChanged: isDisabled ? null : (v) => _toggleSelection(santri),
                                        activeColor: Colors.blue,
                                      )
                                    : null,
                                  onTap: isDisabled ? null : () {
                                    if (widget.isMultiSelect) {
                                      _toggleSelection(santri);
                                    } else {
                                      context.pop(santri);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
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
