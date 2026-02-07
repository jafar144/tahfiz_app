import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_state.dart';

class EditHalaqahPage extends StatefulWidget {
  const EditHalaqahPage({super.key});

  @override
  State<EditHalaqahPage> createState() => _EditHalaqahPageState();
}

class _EditHalaqahPageState extends State<EditHalaqahPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  String? _selectedTeacherId;
  String? _selectedTeacherName;
  String _status = 'Active';
  List<String> _selectedSantriIds = [];
  List<HalaqahSantri> _selectedSantris = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<HalaqahDetailCubit>();
      cubit.init();
    });
  }

  void _populateData(Halaqah halaqah) {
    setState(() {
      _nameController.text = halaqah.name;
      _roomController.text = halaqah.room;
      _selectedTeacherId = halaqah.teacherId;
      _selectedTeacherName = halaqah.teacherName;
      _status = halaqah.status;
      _selectedSantris = List.from(halaqah.santris);
      _selectedSantriIds = halaqah.santris.map((s) => s.id).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HalaqahDetailCubit, HalaqahDetailState>(
      listener: (context, state) {
        if (state is HalaqahDetailLoaded) {
          _populateData(state.halaqah);
        }
        if (state is HalaqahDetailSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Halaqah berhasil diupdate')),
          );
          context.pop();
        }
        if (state is HalaqahDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is HalaqahDetailLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is! HalaqahDetailLoaded) {
          return const Scaffold(
            body: Center(child: Text('Data tidak ditemukan')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Halaqah'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailInfo(context, state),
                  const SizedBox(height: 24),
                  _buildPengajarSection(context, state),
                  const SizedBox(height: 24),
                  _buildSantriSection(context, state),
                  const SizedBox(height: 24),
                  _buildStatusSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailInfo(BuildContext context, HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 Detail Kelas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Halaqah',
            border: OutlineInputBorder(),
            hintText: 'Masukkan nama halaqah',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _roomController,
          decoration: const InputDecoration(
            labelText: 'Ruangan',
            border: OutlineInputBorder(),
            hintText: 'Masukkan nama ruangan',
          ),
        ),
      ],
    );
  }

  Widget _buildPengajarSection(BuildContext context, HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👨‍🏫 Pengajar (Asatidz)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            if (state.asatidzList.isNotEmpty) {
              _showAsatidzBottomSheet(context, state.asatidzList);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data asatidz tidak tersedia')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedTeacherName ?? 'Pilih Asatidz',
                    style: TextStyle(
                      color: _selectedTeacherName != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAsatidzBottomSheet(BuildContext context, List<AsatidzEntity> asatidzList) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: asatidzList.length,
          itemBuilder: (context, index) {
            final asatidz = asatidzList[index];
            return ListTile(
              title: Text(asatidz.name),
              subtitle: Text(asatidz.nis),
              onTap: () {
                setState(() {
                  _selectedTeacherId = asatidz.id;
                  _selectedTeacherName = asatidz.name;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSantriSection(BuildContext context, HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👥 Pilih Santri-Santri',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            if (state.santriList.isNotEmpty) {
              _showSantriBottomSheet(context, state.santriList);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data santri tidak tersedia')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedSantris.isEmpty
                        ? 'Pilih Santri'
                        : '${_selectedSantris.length} santri dipilih',
                    style: TextStyle(
                      color: _selectedSantris.isNotEmpty ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_selectedSantris.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSantris.map((santri) {
              return Chip(
                label: Text(santri.name),
                onDeleted: () {
                  setState(() {
                    _selectedSantris.removeWhere((s) => s.id == santri.id);
                    _selectedSantriIds.remove(santri.id);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showSantriBottomSheet(BuildContext context, List<SantriEntity> santriList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Santri',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Selesai'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: santriList.length,
                        itemBuilder: (context, index) {
                          final santri = santriList[index];
                          final isSelected = _selectedSantriIds.contains(santri.id);
                          return CheckboxListTile(
                            title: Text(santri.name),
                            subtitle: Text(santri.nis),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  _selectedSantriIds.add(santri.id);
                                  _selectedSantris.add(HalaqahSantri(
                                    id: santri.id,
                                    name: santri.name,
                                  ));
                                } else {
                                  _selectedSantriIds.remove(santri.id);
                                  _selectedSantris.removeWhere((s) => s.id == santri.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard('Active', Icons.check_circle, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard('Non-Active', Icons.cancel, Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(String status, IconData icon, Color color) {
    final isSelected = _status == status;
    return InkWell(
      onTap: () {
        setState(() {
          _status = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, HalaqahDetailLoaded state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is HalaqahDetailLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: state is HalaqahDetailLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '💾 Simpan Perubahan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _submit() {
    final cubit = context.read<HalaqahDetailCubit>();
    final currentState = cubit.state as HalaqahDetailLoaded;
    final halaqah = currentState.halaqah;

    final updatedHalaqah = Halaqah(
      id: halaqah.id,
      programId: halaqah.programId,
      scheduleId: halaqah.scheduleId,
      name: _nameController.text,
      room: _roomController.text,
      teacherId: _selectedTeacherId ?? halaqah.teacherId,
      teacherName: _selectedTeacherName ?? halaqah.teacherName,
      status: _status,
      santris: _selectedSantris,
    );

    cubit.updateHalaqah(updatedHalaqah);
  }
}
