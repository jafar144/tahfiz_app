import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_state.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/widgets/asatidz_card.dart';
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
      backgroundColor: Colors.white,
      appBar: const AiwaAppBar(title: 'Pilih Asatidz'),
      body: BlocBuilder<AsatidzCubit, AsatidzState>(
        builder: (context, state) {
          final isLoading = state is AsatidzInitial || state is AsatidzLoading;
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

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AiwaSearch(
                    controller: _searchController,
                    onSubmitted: (_) => _onSearch(context),
                    onSearch: () => _onSearch(context),
                    hintText: 'Cari Asatidz...',
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is AsatidzError) {
                        return Center(child: Text(state.message));
                      }

                      if (state is AsatidzLoaded && dataList.isEmpty) {
                        return Center(
                          child: Text(
                            'Data asatidz tidak ditemukan',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
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
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= dataList.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final asatidz = dataList[index];
                            final isSelected =
                                asatidz.id == widget.initialSelectedId;
                            final isDisabled = widget.disabledIds.contains(
                              asatidz.id,
                            );

                            return AsatidzCard(
                              asatidz,
                              isSelected: isSelected,
                              isEnabled: !isLoading && !isDisabled,
                              onTap: () => Navigator.pop(context, asatidz),
                              trailing: Icon(
                                isDisabled
                                    ? Icons.block_rounded
                                    : isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 21,
                                color: isDisabled
                                    ? Colors.grey.shade500
                                    : isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                              ),
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
        },
      ),
    );
  }
}
