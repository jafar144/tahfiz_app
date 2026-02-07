import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_state.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/widgets/asatidz_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminAsatidzPage extends StatefulWidget {
  const AdminAsatidzPage({super.key});

  @override
  State<AdminAsatidzPage> createState() => _AdminAsatidzPageState();
}

class _AdminAsatidzPageState extends State<AdminAsatidzPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool? _filterIsActive;
  String _searchKeyword = '';

  final List<AsatidzEntity> _skeletonData = List.generate(
    5,
    (index) => AsatidzEntity(
      id: 'skeleton_$index',
      name: 'Nama Asatidz Placeholder',
      nis: '12345',
      jenisKelamin: 'L',
      isActive: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  void _fetchData() {
    context.read<AsatidzCubit>().loadAsatidz(
          keyword: _searchKeyword,
          isActive: _filterIsActive,
        );
  }

  void _resetAndFetchData() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
      _filterIsActive = null;
    });
    _fetchData();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AsatidzCubit>().loadMoreAsatidz();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  void _onSearch() {
    UiUtils.unfocus(context);
    setState(() {
      _searchKeyword = _searchController.text;
    });
    _fetchData();
  }

  void _onFilterChanged(bool? isActive) {
    setState(() {
      _filterIsActive = isActive;
    });
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Data Asatidz',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_asatidz_fab',
        onPressed: () async {
          await context.pushNamed(RouteNames.addAsatidz);
          if (mounted) {
            _resetAndFetchData();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _onSearch(),
                        decoration: InputDecoration(
                          hintText: 'Cari asatidz...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _onSearch,
                        icon: const Icon(Icons.search, color: Colors.white),
                        tooltip: 'Cari',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Aktif', true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tidak Aktif', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: BlocBuilder<AsatidzCubit, AsatidzState>(
              builder: (context, state) {
                // Determine logic for Skeletonizer
                final isLoading = state is AsatidzLoading;
                final List<AsatidzEntity> displayList;
                
                if (isLoading) {
                  displayList = _skeletonData;
                } else if (state is AsatidzLoaded) {
                  displayList = state.asatidz;
                } else {
                  displayList = [];
                }

                if (state is AsatidzLoaded && state.asatidz.isEmpty) {
                   return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada data asatidz',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                }

                if (state is AsatidzError) {
                  return Center(child: Text(state.message));
                }

                return Skeletonizer(
                  enabled: isLoading,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: displayList.length + (state is AsatidzLoaded && state.isFetchingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= displayList.length) {
                         return Skeletonizer(
                           enabled: true,
                           child: AsatidzCard(
                             _skeletonData.first,
                             onReturn: () {},
                           ),
                         );
                      }
                      return AsatidzCard(
                        displayList[index],
                        onReturn: _resetAndFetchData,
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

  Widget _buildFilterChip(String label, bool? value) {
    final isSelected = _filterIsActive == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(value),
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
    );
  }
}
