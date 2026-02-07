import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SelectSantriPage extends StatefulWidget {
  final String? genderFiltered;
  final List<SantriEntity> initialSelection;
  final List<String> disabledIds;

  const SelectSantriPage({
    super.key,
    this.genderFiltered,
    this.initialSelection = const [],
    this.disabledIds = const [],
  });

  @override
  State<SelectSantriPage> createState() => _SelectSantriPageState();
}

class _SelectSantriPageState extends State<SelectSantriPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Map untuk menyimpan entity yang terpilih agar data tidak hilang saat search/pagination
  late Map<String, SantriEntity> _selectedMap;

  @override
  void initState() {
    super.initState();
    _selectedMap = {for (var e in widget.initialSelection) e.id: e};
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastLoadTime = 0;

  void _onScroll() {
    if (_isBottom) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastLoadTime < 500) return; // Throttle 500ms
      _lastLoadTime = now;
      context.read<SantriCubit>().loadMoreSantri();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  void _onSearch(BuildContext context) {
    UiUtils.unfocus(context);
    context.read<SantriCubit>().loadSantri(
      keyword: _searchController.text,
      isActive: true,
      gender: widget.genderFiltered,
    );
  }

  void _toggleSelection(SantriEntity santri) {
    setState(() {
      if (_selectedMap.containsKey(santri.id)) {
        _selectedMap.remove(santri.id);
      } else {
        _selectedMap[santri.id] = santri;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Santri'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedMap.values.toList());
            },
            child: Text(
              'Selesai (${_selectedMap.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Santri...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: (_) => _onSearch(context),
            ),
          ),
          Expanded(
            child: BlocBuilder<SantriCubit, SantriState>(
              builder: (context, state) {
                      final isLoading = state is SantriLoading;
                      // Dummy data for skeleton
                      final List<SantriEntity> dataList;
                      if (state is SantriLoaded) {
                        dataList = state.santri;
                      } else {
                        dataList = List.generate(
                          6,
                          (index) => SantriEntity(
                            id: 'dummy_$index',
                            name: 'Nama Santri Placeholder',
                            nis: '12345',
                            jenisKelamin: widget.genderFiltered ?? 'L',
                            isActive: true,
                            kelas: '1A',
                            isFree: false,
                            nomorWali: '',
                            pembimbing: '',
                          ),
                        );
                      }

                      if (state is SantriLoaded && state.santri.isEmpty) {
                        return Center(
                          child: Text(
                            'Tidak ada data santri ditemukan',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      if (state is SantriError) {
                        return Center(child: Text(state.message));
                      }

                      return Skeletonizer(
                        enabled: isLoading,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: dataList.length + (state is SantriLoaded && state.isFetchingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index >= dataList.length) {
                               return const Center(child: Padding(
                                 padding: EdgeInsets.all(8.0),
                                 child: CircularProgressIndicator(),
                               ));
                            }
                            
                            final santri = dataList[index];
                            final isSelected = _selectedMap.containsKey(santri.id);
                            final isDisabled = widget.disabledIds.contains(santri.id);

                            return CheckboxListTile(
                              value: isSelected,
                              enabled: !isDisabled,
                              onChanged: (isLoading || isDisabled) ? null : (_) => _toggleSelection(santri),
                              title: Text(
                                santri.name, 
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDisabled ? Colors.grey : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                isDisabled ? '${santri.nis} (Tidak Tersedia)' : santri.nis,
                                style: TextStyle(
                                  color: isDisabled ? Colors.red.shade300 : null,
                                ),
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: isDisabled 
                                    ? Colors.grey 
                                    : (isSelected ? Colors.green : Colors.grey.shade200),
                                child: Text(
                                  santri.name[0], 
                                  style: TextStyle(color: isSelected && !isDisabled ? Colors.white : Colors.black87)
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              tileColor: isDisabled ? Colors.grey.shade50 : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );

  }
}
