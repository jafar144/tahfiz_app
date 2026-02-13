import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  String? _selectedTeacherId;
  String? _selectedTeacherName;
  String _status = 'Active';
  List<HalaqahSantri> _selectedSantris = [];
  List<String> _selectedScheduleIds = [];
  List<String> _selectedScheduleDisplays = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<HalaqahDetailCubit>();
      cubit.init();
    });
  }

  void _populateData(Halaqah halaqah, HalaqahDetailLoaded state) {
    if (_nameController.text.isEmpty) {
        _nameController.text = halaqah.name;
        _roomController.text = halaqah.room;
        _selectedTeacherId = halaqah.teacherId;
        _selectedTeacherName = halaqah.teacherName;
        _status = halaqah.status;
        _selectedSantris = List.from(halaqah.santris);
        _selectedScheduleIds = List.from(halaqah.scheduleIds);
        
        _selectedScheduleDisplays = halaqah.scheduleIds.map((scheduleId) {
          try {
            final schedule = state.schedules.firstWhere(
              (s) => s.id == scheduleId,
            );
            final dayName = _getDayName(schedule.day);
            return '$dayName, ${schedule.startTime} - ${schedule.endTime}';
          } catch (e) {
            return 'Jadwal tidak ditemukan';
          }
        }).toList();
    }
  }

  String _getDayName(int day) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
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
          _populateData(state.halaqah, state);
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
            surfaceTintColor: Colors.white,
            title: const Text('Edit Halaqah'),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailInfo(),
                const SizedBox(height: 24),
                _buildScheduleSection(state),
                const SizedBox(height: 24),
                _buildPengajarSection(state),
                const SizedBox(height: 24),
                _buildSantriSection(state),
                const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 32),
                _buildSaveButton(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Kelas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AiwaTextField(
          label: 'Nama Halaqah',
          hint: 'Masukkan nama halaqah',
          icon: Icons.class_outlined,
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        AiwaTextField(
          label: 'Ruangan',
          hint: 'Masukkan nama ruangan',
          icon: Icons.meeting_room_outlined,
          controller: _roomController,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildScheduleSection(HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Jadwal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_selectedScheduleIds.isNotEmpty)
              Text(
                '${_selectedScheduleIds.length} dipilih',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              )
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (modalContext) {
                return StatefulBuilder(
                  builder: (BuildContext _, StateSetter setModalState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Pilih Jadwal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: state.schedules.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, index) {
                              final schedule = state.schedules[index];
                              final dayName = _getDayName(schedule.day);
                              final display = '$dayName, ${schedule.startTime} - ${schedule.endTime}';
                              final isSelected = _selectedScheduleIds.contains(schedule.id);
                              
                              return ListTile(
                                title: Text(display),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                                onTap: () {
                                   if (isSelected) {
                                     _selectedScheduleIds.remove(schedule.id);
                                     _selectedScheduleDisplays.remove(display);
                                   } else {
                                     _selectedScheduleIds.add(schedule.id);
                                     _selectedScheduleDisplays.add(display);
                                   }
                                   setModalState(() {});
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(modalContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Selesai (${_selectedScheduleIds.length} dipilih)'),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedScheduleIds.isEmpty
                        ? 'Pilih Jadwal'
                        : '${_selectedScheduleIds.length} jadwal dipilih',
                    style: TextStyle(
                      color: _selectedScheduleIds.isEmpty ? Colors.grey : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_selectedScheduleDisplays.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedScheduleDisplays.asMap().entries.map((entry) {
              final index = entry.key;
              final display = entry.value;
              return Chip(
                label: Text(display),
                backgroundColor: Colors.blue.shade50,
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedScheduleIds.removeAt(index);
                    _selectedScheduleDisplays.removeAt(index);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPengajarSection(HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengajar (Asatidz)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AiwaClickableInput(
          label: 'Pengajar',
          value: _selectedTeacherName ?? 'Pilih Pengajar',
          icon: Icons.person_outline,
          onTap: () async {
            final unavailable = state.unavailableTeacherIds;

            final result = await context.pushNamed(
              RouteNames.selectAsatidz,
              extra: {
                'gender': null, 
                'initialSelectedId': _selectedTeacherId,
                'disabledIds': unavailable,
              },
            );

            if (result != null && result is AsatidzEntity) {
              setState(() {
                _selectedTeacherId = result.id;
                _selectedTeacherName = result.name;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSantriSection(HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text(
              'Santri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_selectedSantris.isNotEmpty)
              Text(
                '${_selectedSantris.length} dipilih',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              )
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final initialEntities = _selectedSantris.map((h) => SantriEntity(
              id: h.id, 
              name: h.name, 
              nis: h.nis, 
              jenisKelamin: 'L',
              isActive: true, 
              kelas: '', 
              isFree: false, 
              nomorWali: '', 
              pembimbing: ''
            )).toList();

            final unavailable = state.unavailableSantriIds;

            final result = await context.pushNamed(
              RouteNames.selectSantri,
              extra: {
                'gender': null,
                'initialSelection': initialEntities,
                'disabledIds': unavailable,
              },
            );

            if (result != null && result is List<SantriEntity>) {
              setState(() {
                _selectedSantris = result.map((e) => HalaqahSantri(id: e.id, name: e.name, nis: e.nis)).toList();
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.grey),
                 const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedSantris.isEmpty
                        ? 'Pilih Santri'
                        : _selectSantrisPreview(),
                    style: TextStyle(
                      color: _selectedSantris.isEmpty ? Colors.grey : Colors.black87,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
                backgroundColor: Colors.blue.shade50,
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedSantris.removeWhere((s) => s.id == santri.id);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _selectSantrisPreview() {
    return _selectedSantris.map((e) => e.name).join(', ');
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AiwaSelectionCard(
                label: 'Active',
                icon: Icons.check_circle,
                isSelected: _status == 'Active',
                activeColor: Colors.green,
                onTap: () => setState(() => _status = 'Active'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AiwaSelectionCard(
                label: 'Non-Active',
                icon: Icons.cancel,
                isSelected: _status == 'Non-Active',
                activeColor: Colors.red,
                onTap: () => setState(() => _status = 'Non-Active'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(HalaqahDetailLoaded state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Simpan Perubahan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _submit() {
    final cubit = context.read<HalaqahDetailCubit>();
    if (cubit.state is! HalaqahDetailLoaded) return;
    
    final currentState = cubit.state as HalaqahDetailLoaded;
    final halaqah = currentState.halaqah;

    if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama halaqah wajib diisi')));
        return;
    }

    if (_selectedScheduleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu jadwal')));
      return;
    }

    final updatedHalaqah = Halaqah(
      id: halaqah.id,
      programId: halaqah.programId,
      scheduleIds: _selectedScheduleIds,
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
