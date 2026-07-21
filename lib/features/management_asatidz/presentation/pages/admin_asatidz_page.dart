import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
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
    context.read<AsatidzCubit>().loadAsatidz(keyword: _searchKeyword);
  }

  void _resetAndFetchData() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
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
      appBar: const AiwaAppBar(title: 'Data Asatidz'),
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
                AiwaSearch(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearch(),
                  onSearch: _onSearch,
                  hintText: 'Cari Asatidz...',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<AsatidzCubit, AsatidzState>(
              builder: (context, state) {
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
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
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
                    itemCount:
                        displayList.length +
                        (state is AsatidzLoaded && state.isFetchingMore
                            ? 1
                            : 0),
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
}
