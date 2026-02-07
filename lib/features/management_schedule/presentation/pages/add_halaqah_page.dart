import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_state.dart';

class AddHalaqahPage extends StatefulWidget {
  const AddHalaqahPage({super.key});

  @override
  State<AddHalaqahPage> createState() => _AddHalaqahPageState();
}

class _AddHalaqahPageState extends State<AddHalaqahPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  String? _selectedGender;
  String? _selectedSession;
  String? _selectedScheduleId;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  List<String> _selectedSantriIds = [];
  List<HalaqahSantri> _selectedSantris = [];

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddHalaqahCubit, AddHalaqahState>(
      listener: (context, state) {
        if (state is AddHalaqahSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Halaqah berhasil ditambahkan')),
          );
          context.pop();
        }
        if (state is AddHalaqahError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tambah Halaqah'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKategoriKelas(context, state),
                  const SizedBox(height: 24),
                  _buildDetailInfo(context, state),
                  const SizedBox(height: 24),
                  _buildPengajarSection(context, state),
                  const SizedBox(height: 24),
                  _buildSantriSection(context, state),
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

  Widget _buildKategoriKelas(BuildContext context, AddHalaqahState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👥 Kategori Kelas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard('Putra', Icons.male, state),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderCard('Putri', Icons.female, state),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedGender != null && state is AddHalaqahLoaded)
          _buildSessionDropdown(state),
      ],
    );
  }

  Widget _buildGenderCard(String gender, IconData icon, AddHalaqahState state) {
    final genderCode = gender == 'Putra' ? 'L' : 'P';
    final isSelected = _selectedGender == genderCode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = genderCode;
          _selectedSession = null;
          _selectedScheduleId = null;
          _selectedTeacherId = null;
          _selectedTeacherName = null;
          _selectedSantriIds = [];
          _selectedSantris = [];
        });
        context.read<AddHalaqahCubit>().loadInitialData(genderCode);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDropdown(AddHalaqahLoaded state) {
    debugPrint(state.sessions.map((e) => e.name).toList().toString());
    return DropdownButtonFormField<String>(
      value: _selectedSession,
      decoration: const InputDecoration(
        labelText: 'Sesi',
        border: OutlineInputBorder(),
        hintText: 'Pilih Sesi',
      ),
      items: state.sessions.map((session) {
        return DropdownMenuItem(
          value: session.id,
          child: Text(session.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSession = value;
          _selectedScheduleId = null;
        });
        if (value != null) {
          context.read<AddHalaqahCubit>().loadSchedulesAndPeople(value, _selectedGender!);
        }
      },
    );
  }

  Widget _buildDetailInfo(BuildContext context, AddHalaqahState state) {
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
        const SizedBox(height: 16),
        BlocBuilder<AddHalaqahCubit, AddHalaqahState>(
          builder: (context, scheduleState) {
            if (scheduleState is AddHalaqahLoaded && scheduleState.schedules.isNotEmpty) {
              return _buildScheduleDropdown(scheduleState);
            }
            return _buildSchedulePlaceholder();
          },
        ),
      ],
    );
  }

  Widget _buildScheduleDropdown(AddHalaqahLoaded state) {
    debugPrint('DEBUG: Schedules count: ${state.schedules.length}');
    return DropdownButtonFormField<String>(
      value: _selectedScheduleId,
      decoration: const InputDecoration(
        labelText: 'Jadwal',
        border: OutlineInputBorder(),
        hintText: 'Pilih Jadwal',
      ),
      items: state.schedules.map((schedule) {
        final dayName = _getDayName(schedule.day);
        debugPrint('DEBUG: Schedule - ID: ${schedule.id}, Day: $dayName, Time: ${schedule.startTime} - ${schedule.endTime}');
        return DropdownMenuItem(
          value: schedule.id,
          child: Text('$dayName - ${schedule.startTime} - ${schedule.endTime}'),
        );
      }).toList(),
      onChanged: (value) {
        debugPrint('DEBUG: Selected schedule ID: $value');
        setState(() {
          _selectedScheduleId = value;
        });
      },
    );
  }

  Widget _buildSchedulePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pilih sesi terlebih dahulu untuk memuat jadwal',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[(day - 1) % 7];
  }

  Widget _buildPengajarSection(BuildContext context, AddHalaqahState state) {
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
            if (state is AddHalaqahLoaded) {
              if (state.asatidzList.isNotEmpty) {
                _showAsatidzBottomSheet(context, state.asatidzList);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilih sesi terlebih dahulu untuk memuat data asatidz')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pilih gender dan sesi terlebih dahulu')),
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

  Widget _buildSantriSection(BuildContext context, AddHalaqahState state) {
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
            if (state is AddHalaqahLoaded) {
              if (state.santriList.isNotEmpty) {
                _showSantriBottomSheet(context, state.santriList);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilih sesi terlebih dahulu untuk memuat data santri')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pilih gender dan sesi terlebih dahulu')),
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

  Widget _buildSaveButton(BuildContext context, AddHalaqahState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is AddHalaqahLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: state is AddHalaqahLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '💾 Simpan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _submit() {
    print('DEBUG SUBMIT:');
    print('  Gender: $_selectedGender');
    print('  Session: $_selectedSession');
    print('  ScheduleId: $_selectedScheduleId');
    print('  TeacherId: $_selectedTeacherId');
    print('  TeacherName: $_selectedTeacherName');
    print('  Santri count: ${_selectedSantris.length}');
    
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gender terlebih dahulu')),
      );
      return;
    }

    if (_selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sesi terlebih dahulu')),
      );
      return;
    }

    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jadwal terlebih dahulu')),
      );
      return;
    }

    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pengajar terlebih dahulu')),
      );
      return;
    }

    final halaqah = Halaqah(
      id: '',
      programId: _selectedSession!,
      scheduleId: _selectedScheduleId!,
      name: _nameController.text,
      room: _roomController.text,
      teacherId: _selectedTeacherId!,
      teacherName: _selectedTeacherName!,
      status: 'Active',
      santris: _selectedSantris,
    );

    context.read<AddHalaqahCubit>().createHalaqah(halaqah);
  }
}
