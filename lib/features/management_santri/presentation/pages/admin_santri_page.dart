import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_chip.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminSantriPage extends StatefulWidget {
  const AdminSantriPage({super.key});

  @override
  State<AdminSantriPage> createState() => _AdminSantriPageState();
}

class _AdminSantriPageState extends State<AdminSantriPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedSession;
  String? _selectedGender;
  String? _selectedClass;
  String? _selectedAsatidzId;
  bool? _selectedIsFree;
  bool? _selectedIsActive = true;
  bool? _selectedHasPhoto;
  bool? _selectedHasHalaqah;
  SantriSortBy _selectedSortBy = SantriSortBy.nis;
  String _searchKeyword = '';

  List<AsatidzEntity> _asatidzList = [];

  final List<SantriEntity> _skeletonData = List.generate(
    5,
    (index) => SantriEntity(
      id: 'skeleton_$index',
      name: 'Nama Santri Placeholder',
      nis: '12345',
      kelas: 'Tahfiz 1',
      jenisKelamin: 'L',
      isActive: true,
      isFree: false,
      nomorWali: '0812...',
      pembimbing: 'Ustadz Fulan',
    ),
  );

  int get _activeFilterCount {
    var count = 0;
    if (_selectedIsActive != true) count++;
    if (_selectedSession != null) count++;
    if (_selectedGender != null) count++;
    if (_selectedClass != null) count++;
    if (_selectedAsatidzId != null) count++;
    if (_selectedIsFree != null) count++;
    if (_selectedHasPhoto != null) count++;
    if (_selectedHasHalaqah != null) count++;
    return count;
  }

  String get _sortLabel => _selectedSortBy == SantriSortBy.nis ? 'NIS' : 'Nama';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchAsatidzList();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() {
    return context.read<SantriCubit>().loadSantri(
      keyword: _searchKeyword,
      isActive: _selectedIsActive,
      session: _selectedSession,
      gender: _selectedGender,
      kelas: _selectedClass,
      asatidzId: _selectedAsatidzId,
      isFree: _selectedIsFree,
      hasPhoto: _selectedHasPhoto,
      hasHalaqah: _selectedHasHalaqah,
      sortBy: _selectedSortBy,
    );
  }

  Future<void> _fetchAsatidzList() async {
    try {
      final list = await context.read<SantriCubit>().fetchAsatidzList();
      if (!mounted) return;
      setState(() {
        _asatidzList = List.of(list)
          ..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );
      });
    } catch (_) {
      // Daftar santri tetap dapat dipakai meski opsi asatidz gagal dimuat.
    }
  }

  void _onSearch() {
    UiUtils.unfocus(context);
    setState(() {
      _searchKeyword = _searchController.text.trim();
    });
    _fetchData();
  }

  void _resetAndFetchData() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
      _selectedSession = null;
      _selectedGender = null;
      _selectedClass = null;
      _selectedAsatidzId = null;
      _selectedIsFree = null;
      _selectedIsActive = true;
      _selectedHasPhoto = null;
      _selectedHasHalaqah = null;
      _selectedSortBy = SantriSortBy.nis;
    });
    _fetchData();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SantriCubit>().loadMoreSantri();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const AiwaAppBar(title: 'Data Santri'),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_santri_fab',
        onPressed: () async {
          await context.pushNamed(RouteNames.addSantri);
          if (mounted) _fetchData();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchAndControls(),
          const SizedBox(height: 8),
          Expanded(child: _buildSantriList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AiwaSearch(
            controller: _searchController,
            onSubmitted: (_) => _onSearch(),
            onSearch: _onSearch,
            hintText: 'Cari nama atau NIS...',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ListControlButton(
                  key: const Key('santri_filter_button'),
                  icon: Icons.tune_rounded,
                  label: 'Filter',
                  badgeCount: _activeFilterCount,
                  isActive: _activeFilterCount > 0,
                  onTap: _showFilterSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ListControlButton(
                  key: const Key('santri_sort_button'),
                  icon: Icons.swap_vert_rounded,
                  label: 'Urutkan: $_sortLabel',
                  onTap: _showSortSheet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BlocBuilder<SantriCubit, SantriState>(
                builder: (context, state) {
                  if (state is SantriLoaded) {
                    return Row(
                      key: const Key('santri_result_count'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${state.totalCount} santri ditemukan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }
                  if (state is SantriLoading) {
                    return Text(
                      'Menghitung hasil...',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSantriList() {
    return BlocBuilder<SantriCubit, SantriState>(
      builder: (context, state) {
        final isLoading = state is SantriLoading;
        final displayList = switch (state) {
          SantriLoaded(:final santri) => santri,
          _ when isLoading => _skeletonData,
          _ => <SantriEntity>[],
        };

        if (state is SantriLoaded && state.santri.isEmpty) {
          return _EmptySantriState(
            canReset: _activeFilterCount > 0 || _searchKeyword.isNotEmpty,
            onReset: _resetAndFetchData,
          );
        }

        if (state is SantriError) {
          return _ErrorSantriState(message: state.message, onRetry: _fetchData);
        }

        return RefreshIndicator(
          onRefresh: _fetchData,
          child: Skeletonizer(
            enabled: isLoading,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  displayList.length +
                  (state is SantriLoaded && state.isFetchingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= displayList.length) {
                  return Skeletonizer(
                    enabled: true,
                    child: SantriCard(_skeletonData.first, onReturn: () {}),
                  );
                }
                return SantriCard(displayList[index], onReturn: _fetchData);
              },
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    String? tempSession = _selectedSession;
    String? tempGender = _selectedGender;
    String? tempClass = _selectedClass;
    String? tempAsatidzId = _selectedAsatidzId;
    bool? tempIsFree = _selectedIsFree;
    bool? tempIsActive = _selectedIsActive;
    bool? tempHasPhoto = _selectedHasPhoto;
    bool? tempHasHalaqah = _selectedHasHalaqah;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void resetTemporaryFilters() {
            setModalState(() {
              tempSession = null;
              tempGender = null;
              tempClass = null;
              tempAsatidzId = null;
              tempIsFree = null;
              tempIsActive = true;
              tempHasPhoto = null;
              tempHasHalaqah = null;
            });
          }

          return AiwaBottomSheet(
            title: 'Filter data santri',
            onReset: resetTemporaryFilters,
            onApply: () {
              setState(() {
                _selectedSession = tempSession;
                _selectedGender = tempGender;
                _selectedClass = tempClass;
                _selectedAsatidzId = tempAsatidzId;
                _selectedIsFree = tempIsFree;
                _selectedIsActive = tempIsActive;
                _selectedHasPhoto = tempHasPhoto;
                _selectedHasHalaqah = tempHasHalaqah;
              });
              Navigator.pop(sheetContext);
              _fetchData();
            },
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.58,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      icon: Icons.verified_user_outlined,
                      title: 'Status santri',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildModalChip(
                            'Aktif',
                            tempIsActive == true,
                            () => setModalState(() => tempIsActive = true),
                          ),
                          _buildModalChip(
                            'Tidak aktif',
                            tempIsActive == false,
                            () => setModalState(() => tempIsActive = false),
                          ),
                          _buildModalChip(
                            'Semua',
                            tempIsActive == null,
                            () => setModalState(() => tempIsActive = null),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      icon: Icons.people_outline_rounded,
                      title: 'Jenis kelamin',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildNullableChip(
                            label: 'Putra',
                            selectedValue: tempGender,
                            value: 'L',
                            onChanged: (value) =>
                                setModalState(() => tempGender = value),
                          ),
                          _buildNullableChip(
                            label: 'Putri',
                            selectedValue: tempGender,
                            value: 'P',
                            onChanged: (value) =>
                                setModalState(() => tempGender = value),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      icon: Icons.schedule_outlined,
                      title: 'Sesi',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.classTypes.map((type) {
                          return _buildNullableChip(
                            label: type,
                            selectedValue: tempSession,
                            value: type,
                            onChanged: (value) =>
                                setModalState(() => tempSession = value),
                          );
                        }).toList(),
                      ),
                    ),
                    _FilterSection(
                      icon: Icons.school_outlined,
                      title: 'Kelas',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.santriClasses.map((kelas) {
                          return _buildNullableChip(
                            label: kelas,
                            selectedValue: tempClass,
                            value: kelas,
                            onChanged: (value) =>
                                setModalState(() => tempClass = value),
                          );
                        }).toList(),
                      ),
                    ),
                    _FilterSection(
                      icon: Icons.account_circle_outlined,
                      title: 'Foto profil',
                      description: 'Kelengkapan foto pada profil santri.',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildNullableBoolChip(
                            label: 'Ada foto',
                            selectedValue: tempHasPhoto,
                            value: true,
                            onChanged: (value) =>
                                setModalState(() => tempHasPhoto = value),
                          ),
                          _buildNullableBoolChip(
                            label: 'Belum ada foto',
                            selectedValue: tempHasPhoto,
                            value: false,
                            onChanged: (value) =>
                                setModalState(() => tempHasPhoto = value),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      icon: Icons.groups_2_outlined,
                      title: 'Halaqah',
                      description: 'Status penempatan santri di halaqah.',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildNullableBoolChip(
                            label: 'Sudah ada halaqah',
                            selectedValue: tempHasHalaqah,
                            value: true,
                            onChanged: (value) => setModalState(() {
                              tempHasHalaqah = value;
                            }),
                          ),
                          _buildNullableBoolChip(
                            label: 'Belum ada halaqah',
                            selectedValue: tempHasHalaqah,
                            value: false,
                            onChanged: (value) => setModalState(() {
                              tempHasHalaqah = value;
                              if (value == false) tempAsatidzId = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      icon: Icons.person_pin_circle_outlined,
                      title: 'Asatidz pembimbing',
                      child: _asatidzList.isEmpty
                          ? Text(
                              'Data asatidz belum tersedia.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _asatidzList.map((asatidz) {
                                return _buildNullableChip(
                                  label: asatidz.name,
                                  selectedValue: tempAsatidzId,
                                  value: asatidz.id,
                                  onChanged: (value) => setModalState(() {
                                    tempAsatidzId = value;
                                    if (value != null &&
                                        tempHasHalaqah == false) {
                                      tempHasHalaqah = null;
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                    ),
                    _FilterSection(
                      icon: Icons.payments_outlined,
                      title: 'Status pembayaran',
                      showDivider: false,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildNullableBoolChip(
                            label: 'Reguler',
                            selectedValue: tempIsFree,
                            value: false,
                            onChanged: (value) =>
                                setModalState(() => tempIsFree = value),
                          ),
                          _buildNullableBoolChip(
                            label: 'Gratis',
                            selectedValue: tempIsFree,
                            value: true,
                            onChanged: (value) =>
                                setModalState(() => tempIsFree = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSortSheet() {
    var tempSortBy = _selectedSortBy;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AiwaBottomSheet(
            title: 'Urutkan data santri',
            resetText: 'Batal',
            resetColor: Colors.grey,
            onReset: () => Navigator.pop(sheetContext),
            onApply: () {
              setState(() => _selectedSortBy = tempSortBy);
              Navigator.pop(sheetContext);
              _fetchData();
            },
            content: Column(
              children: [
                _SortOptionTile(
                  icon: Icons.tag_rounded,
                  title: 'Nomor Induk Santri (NIS)',
                  subtitle: 'Urutan NIS terkecil ke terbesar',
                  isSelected: tempSortBy == SantriSortBy.nis,
                  onTap: () =>
                      setModalState(() => tempSortBy = SantriSortBy.nis),
                ),
                const SizedBox(height: 10),
                _SortOptionTile(
                  icon: Icons.sort_by_alpha_rounded,
                  title: 'Nama santri',
                  subtitle: 'Urutan nama A–Z',
                  isSelected: tempSortBy == SantriSortBy.name,
                  onTap: () =>
                      setModalState(() => tempSortBy = SantriSortBy.name),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalChip(String label, bool isSelected, VoidCallback onTap) {
    return AiwaChoiceChip(label: label, isSelected: isSelected, onTap: onTap);
  }

  Widget _buildNullableChip({
    required String label,
    required String? selectedValue,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildModalChip(
      label,
      selectedValue == value,
      () => onChanged(selectedValue == value ? null : value),
    );
  }

  Widget _buildNullableBoolChip({
    required String label,
    required bool? selectedValue,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return _buildModalChip(
      label,
      selectedValue == value,
      () => onChanged(selectedValue == value ? null : value),
    );
  }
}

class _ListControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  const _ListControlButton({
    super.key,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? Colors.blue.shade700 : Colors.grey.shade800;
    final border = isActive ? Colors.blue.shade300 : Colors.grey.shade300;
    final background = isActive ? Colors.blue.shade50 : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 7),
                SizedBox.square(
                  dimension: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget child;
  final bool showDivider;

  const _FilterSection({
    required this.icon,
    required this.title,
    this.description,
    required this.child,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              description!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ),
        ],
        const SizedBox(height: 10),
        child,
        if (showDivider)
          Divider(height: 30, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySantriState extends StatelessWidget {
  final bool canReset;
  final VoidCallback onReset;

  const _EmptySantriState({required this.canReset, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_outlined,
                size: 34,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Santri tidak ditemukan',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              canReset
                  ? 'Coba ubah kata kunci atau kriteria filter.'
                  : 'Belum ada data santri yang dapat ditampilkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (canReset) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Atur ulang'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorSantriState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorSantriState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
