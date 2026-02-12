import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_chip.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminSantriPage extends StatefulWidget {
  const AdminSantriPage({super.key});

  @override
  State<AdminSantriPage> createState() => _AdminSantriPageState();
}

class _AdminSantriPageState extends State<AdminSantriPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter States
  String? _selectedSession; // Pagi, Sore, Malam
  String? _selectedGender; // L, P
  String? _selectedClass;
  String? _selectedAsatidzId;
  String? _selectedAsatidzName; // For display
  bool? _selectedIsFree;
  
  List<AsatidzEntity> _asatidzList = [];

  String _searchKeyword = '';

  void _fetchData() {
    context.read<SantriCubit>().loadSantri(
      keyword: _searchKeyword,
      isActive: true, 
      session: _selectedSession,
      gender: _selectedGender,
      kelas: _selectedClass,
      asatidzId: _selectedAsatidzId,
      isFree: _selectedIsFree,
    );
  }

  void _onSearch() {
    UiUtils.unfocus(context);
    setState(() {
      _searchKeyword = _searchController.text;
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
      _selectedAsatidzName = null;
      _selectedIsFree = null;
    });
    _fetchData();
  }

  final ScrollController _scrollController = ScrollController();
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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchAsatidzList();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchAsatidzList() async {
    try {
      final list = await context.read<SantriCubit>().fetchAsatidzList();
      if (mounted) {
        setState(() {
          _asatidzList = list;
        });
      }
    } catch (_) {
      // Handle error cleanly or ignore
    }
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
    return currentScroll >= (maxScroll * 0.8);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAsatidzFilter(BuildContext context) {
    String? tempId = _selectedAsatidzId;
    String? tempName = _selectedAsatidzName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AiwaBottomSheet(
            title: 'Filter Asatidz',
            onReset: () {
              setModalState(() {
                tempId = null;
                tempName = null;
              });
            },
            onApply: () {
              setState(() {
                _selectedAsatidzId = tempId;
                _selectedAsatidzName = tempName;
              });
              Navigator.pop(context);
              _fetchData();
            },
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_asatidzList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Tidak ada data asatidz'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _asatidzList.map((asatidz) {
                      return _buildModalChip(
                        asatidz.name,
                        tempId == asatidz.id,
                        () => setModalState(() {
                          if (tempId == asatidz.id) {
                            tempId = null;
                            tempName = null;
                          } else {
                            tempId = asatidz.id;
                            tempName = asatidz.name;
                          }
                        }),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const AiwaAppBar(
        title: 'Data Santri',
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_santri_fab',
        onPressed: () async {
          await context.pushNamed(RouteNames.addSantri);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AiwaSearch(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearch(),
                  onSearch: _onSearch,
                  hintText: 'Cari Santri...',
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AiwaChip(
                        label: _getSessionLabel(), 
                        isSelected: _selectedSession != null || _selectedGender != null,
                        onTap: () => _showSessionFilter(context),
                      ),
                      AiwaChip(
                        label: _selectedClass ?? 'Kelas',
                        isSelected: _selectedClass != null,
                        onTap: () => _showClassFilter(context),
                      ),
                      AiwaChip(
                        label: _selectedAsatidzName ?? 'Asatidz', 
                        isSelected: _selectedAsatidzId != null,
                        onTap: () => _showAsatidzFilter(context),
                      ),
                      AiwaChip(
                        label: _selectedIsFree == null 
                            ? 'Status' 
                            : (_selectedIsFree! ? 'Beasiswa' : 'Reguler'),
                        isSelected: _selectedIsFree != null,
                        onTap: () => _showStatusFilter(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<SantriCubit, SantriState>(
              builder: (context, state) {
                final isLoading = state is SantriLoading;
                final List<SantriEntity> displayList;

                if (isLoading) {
                  displayList = _skeletonData;
                } else if (state is SantriLoaded) {
                  displayList = state.santri;
                } else {
                  displayList = [];
                }

                if (state is SantriLoaded && state.santri.isEmpty) {
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
                          'Santri tidak ditemukan!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
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
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        displayList.length +
                        (state is SantriLoaded && state.isFetchingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= displayList.length) {
                        return Skeletonizer(
                          enabled: true,
                          child: SantriCard(
                            _skeletonData.first,
                            onReturn: () {},
                          ),
                        );
                      }
                      return SantriCard(
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

  void _showStatusFilter(BuildContext context) {
    bool? tempIsFree = _selectedIsFree;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AiwaBottomSheet(
            title: 'Filter Status',
            onReset: () {
              setModalState(() {
                tempIsFree = null;
              });
            },
            onApply: () {
              setState(() {
                _selectedIsFree = tempIsFree;
              });
              Navigator.pop(context);
              _fetchData();
            },
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildModalChip(
                      'Reguler',
                      tempIsFree == false,
                      () => setModalState(() => tempIsFree = tempIsFree == false ? null : false),
                    ),
                    _buildModalChip(
                      'Gratis',
                      tempIsFree == true,
                      () => setModalState(() => tempIsFree = tempIsFree == true ? null : true),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getSessionLabel() {
    if (_selectedSession != null && _selectedGender != null) {
      return '$_selectedSession, ${_selectedGender == 'L' ? 'Putra' : 'Putri'}';
    } else if (_selectedSession != null) {
      return _selectedSession!;
    } else if (_selectedGender != null) {
      return _selectedGender == 'L' ? 'Putra' : 'Putri';
    }
    return 'Sesi';
  }

  void _showSessionFilter(BuildContext context) {
    String? tempSession = _selectedSession;
    String? tempGender = _selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AiwaBottomSheet(
            title: 'Filter Sesi',
            onReset: () {
              setModalState(() {
                tempSession = null;
                tempGender = null;
              });
            },
            onApply: () {
              setState(() {
                _selectedSession = tempSession;
                _selectedGender = tempGender;
              });
              Navigator.pop(context);
              _fetchData();
            },
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jenis Kelamin', style: AppTextStyles.smallContentBlack),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildModalChip(
                      'Putra',
                      tempGender == 'L',
                      () => setModalState(() => tempGender = tempGender == 'L' ? null : 'L'),
                    ),
                    _buildModalChip(
                      'Putri',
                      tempGender == 'P',
                      () => setModalState(() => tempGender = tempGender == 'P' ? null : 'P'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Waktu Sesi', style: AppTextStyles.smallContentBlack),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppConstants.classTypes.map((type) {
                    return _buildModalChip(
                      type,
                      tempSession == type,
                      () => setModalState(() => tempSession = tempSession == type ? null : type),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClassFilter(BuildContext context) {
    String? tempClass = _selectedClass;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AiwaBottomSheet(
            title: 'Filter Kelas',
            onReset: () {
              setModalState(() {
                tempClass = null;
              });
            },
            onApply: () {
              setState(() {
                _selectedClass = tempClass;
              });
              Navigator.pop(context);
              _fetchData();
            },
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.santriClasses.map((cls) {
                    return _buildModalChip(
                      cls,
                      tempClass == cls,
                      () => setModalState(() => tempClass = tempClass == cls ? null : cls),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalChip(String label, bool isSelected, VoidCallback onTap) {
    return AiwaChoiceChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
