import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SelectAsatidzPage extends StatefulWidget {
  final String? genderFiltered;
  final String? initialSelectedId;
  final List<String> disabledIds;

  const SelectAsatidzPage({
    super.key,
    this.genderFiltered,
    this.initialSelectedId,
    this.disabledIds = const [],
  });

  @override
  State<SelectAsatidzPage> createState() => _SelectAsatidzPageState();
}

class _SelectAsatidzPageState extends State<SelectAsatidzPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
      context.read<AsatidzCubit>().loadMoreAsatidz();
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
    context.read<AsatidzCubit>().loadAsatidz(
      keyword: _searchController.text,
      isActive: true,
      gender: widget.genderFiltered,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Asatidz')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Asatidz...',
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
            child: BlocBuilder<AsatidzCubit, AsatidzState>(
              builder: (context, state) {
                final isLoading = state is AsatidzLoading;
                final List<AsatidzEntity> dataList;

                if (state is AsatidzLoaded) {
                  dataList = state.asatidz;
                } else {
                  dataList = List.generate(
                    6,
                    (index) => AsatidzEntity(
                      id: 'dummy_$index',
                      name: 'Nama Asatidz Placeholder',
                      nis: '12345',
                      jenisKelamin: widget.genderFiltered ?? 'L',
                      isActive: true,
                    ),
                  );
                }

                if (state is AsatidzLoaded && state.asatidz.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada data asatidz ditemukan',
                      style: TextStyle(color: Colors.grey[600]),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount:
                        dataList.length +
                        (state is AsatidzLoaded && state.isFetchingMore
                            ? 1
                            : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= dataList.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final asatidz = dataList[index];
                      final isSelected = asatidz.id == widget.initialSelectedId;
                      final isDisabled = widget.disabledIds.contains(
                        asatidz.id,
                      );

                      return ListTile(
                        onTap: isLoading || isDisabled
                            ? null
                            : () {
                                Navigator.pop(context, asatidz);
                              },
                        leading: CircleAvatar(
                          backgroundColor: isDisabled
                              ? Colors.grey
                              : (isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade200),
                          child: Text(
                            asatidz.name[0],
                            style: TextStyle(
                              color: isSelected && !isDisabled
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        title: Text(
                          asatidz.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isDisabled ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          isDisabled
                              ? '${asatidz.nis} (Tidak Tersedia)'
                              : asatidz.nis,
                          style: TextStyle(
                            color: isDisabled ? Colors.red.shade300 : null,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected && !isDisabled
                                ? Colors.blue
                                : Colors.grey.shade200,
                          ),
                        ),
                        tileColor: isDisabled
                            ? Colors.grey.shade50
                            : (isSelected
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.white),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        trailing: isSelected && !isDisabled
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : (isDisabled
                                  ? const Icon(Icons.block, color: Colors.grey)
                                  : null),
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
