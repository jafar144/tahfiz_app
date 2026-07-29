import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
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

  /// Bila aktif, santri yang sudah terhubung dengan halaqah lain tetap dapat
  /// dipilih. Pemilihan hanya bersifat lokal; pemindahan sebenarnya dilakukan
  /// oleh halaman pemanggil ketika form halaqah disimpan.
  final bool allowHalaqahTransfer;

  /// Halaqah yang sedang diedit. Santri yang sudah berada di halaqah ini tidak
  /// dianggap sebagai kandidat transfer dan tidak memerlukan konfirmasi.
  final String? currentHalaqahId;

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
    this.allowHalaqahTransfer = false,
    this.currentHalaqahId,
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
  final Set<String> _confirmedTransferIds = {};
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

  bool _isAssignedToAnotherHalaqah(SantriEntity santri) {
    if (!widget.allowHalaqahTransfer) return false;

    final assignedHalaqahId = santri.halaqahId?.trim();
    if (assignedHalaqahId == null || assignedHalaqahId.isEmpty) return false;

    final currentHalaqahId = widget.currentHalaqahId?.trim();
    return currentHalaqahId == null ||
        currentHalaqahId.isEmpty ||
        assignedHalaqahId != currentHalaqahId;
  }

  bool _isHardDisabled(SantriEntity santri) {
    if (!widget.disabledIds.contains(santri.id)) return false;

    // Dalam mode transfer, ID yang disabled karena sudah memiliki halaqah
    // tetap boleh dipilih. ID tanpa halaqah tetap mengikuti kontrak disabled.
    return !(widget.allowHalaqahTransfer && santri.hasHalaqah);
  }

  Future<bool> _confirmTransferIfNeeded(SantriEntity santri) async {
    if (!_isAssignedToAnotherHalaqah(santri) ||
        _confirmedTransferIds.contains(santri.id)) {
      return true;
    }

    final confirmed = await showAiwaActionSheet<bool>(
      context: context,
      title: 'Santri sudah memiliki halaqah',
      content: Text(
        '${santri.name} sudah terdaftar di halaqah lain. Jika tetap dipilih, '
        'perpindahan baru dilakukan saat Anda menyimpan halaqah.',
      ),
      cancelText: 'Batal',
      confirmText: 'Tetap pilih',
      cancelValue: false,
      confirmValue: true,
      confirmColor: Colors.orange.shade700,
    );

    if (confirmed != true || !mounted) return false;
    _confirmedTransferIds.add(santri.id);
    return true;
  }

  Future<void> _handleSantriTap(SantriEntity santri) async {
    if (_isHardDisabled(santri)) return;

    final isSelected = _selectedSantri.any((s) => s.id == santri.id);
    if (widget.isMultiSelect && isSelected) {
      _toggleSelection(santri);
      return;
    }

    if (!await _confirmTransferIfNeeded(santri) || !mounted) return;

    if (widget.isMultiSelect) {
      _toggleSelection(santri);
    } else {
      context.pop(santri);
    }
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: state is SantriLoading
                                ? 10
                                : santriList.length +
                                      (state is SantriLoaded &&
                                              !state.hasReachedMax
                                          ? 1
                                          : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              // Show spinner at bottom when fetching more (or if there is more data to load)
                              if (state is! SantriLoading &&
                                  index >= santriList.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Skeletonizer(
                                    enabled: true,
                                    child: SantriCard(SantriEntity.dummy()),
                                  ),
                                );
                              }

                              final santri =
                                  (state is SantriLoading || santriList.isEmpty)
                                  ? SantriEntity.dummy()
                                  : santriList[index];

                              final isSelected = _selectedSantri.any(
                                (s) => s.id == santri.id,
                              );
                              final isDisabled = _isHardDisabled(santri);
                              final isTransferCandidate =
                                  _isAssignedToAnotherHalaqah(santri);

                              return Opacity(
                                opacity: isDisabled ? 0.5 : 1.0,
                                child: IgnorePointer(
                                  ignoring: isDisabled,
                                  child: SantriCard(
                                    santri,
                                    trailing:
                                        widget.isMultiSelect ||
                                            isTransferCandidate
                                        ? _SelectionTrailing(
                                            santriId: santri.id,
                                            isTransferCandidate:
                                                isTransferCandidate,
                                            isMultiSelect: widget.isMultiSelect,
                                            isSelected: isSelected,
                                            onChanged: isDisabled
                                                ? null
                                                : () =>
                                                      _handleSantriTap(santri),
                                          )
                                        : null,
                                    // Selalu berikan callback eksplisit agar
                                    // card disabled tidak jatuh ke navigasi
                                    // default menuju Detail Santri.
                                    onTap: () => _handleSantriTap(santri),
                                  ),
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

class _SelectionTrailing extends StatelessWidget {
  final String santriId;
  final bool isTransferCandidate;
  final bool isMultiSelect;
  final bool isSelected;
  final VoidCallback? onChanged;

  const _SelectionTrailing({
    required this.santriId,
    required this.isTransferCandidate,
    required this.isMultiSelect,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isTransferCandidate)
          Tooltip(
            message: 'Sudah terdaftar di halaqah lain',
            child: Container(
              key: Key('santri_transfer_indicator_$santriId'),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 13,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Halaqah lain',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isTransferCandidate && isMultiSelect) const SizedBox(height: 4),
        if (isMultiSelect)
          SizedBox(
            width: 32,
            height: 32,
            child: Checkbox(
              key: Key('santri_select_checkbox_$santriId'),
              value: isSelected,
              onChanged: onChanged == null ? null : (_) => onChanged?.call(),
              activeColor: Colors.blue,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
