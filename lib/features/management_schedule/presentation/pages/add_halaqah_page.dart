import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/utils/format_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_state.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';

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
  String? _selectedSessionId;
  String? _selectedSessionName;
  String? _selectedScheduleId;
  String? _selectedScheduleDisplay;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  
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
            elevation: 0,
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
          'Kategori Kelas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AiwaSelectionCard(
                label: 'Putra',
                icon: Icons.face,
                isSelected: _selectedGender == 'L',
                activeColor: Colors.blue,
                onTap: () => _updateGender(context, 'L'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AiwaSelectionCard(
                label: 'Putri',
                icon: Icons.face_3,
                isSelected: _selectedGender == 'P',
                activeColor: Colors.pink,
                onTap: () => _updateGender(context, 'P'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AiwaClickableInput(
          label: 'Sesi (Program)',
          value: _selectedSessionName ?? 'Pilih Sesi',
          icon: Icons.access_time_filled,
          onTap: () => _handleSessionTap(context, state),
        )
      ],
    );
  }

  void _updateGender(BuildContext context, String gender) {
    if (_selectedGender == gender) return;
    setState(() {
      _selectedGender = gender;
      _selectedSessionId = null;
      _selectedSessionName = null;
      _selectedScheduleId = null;
      _selectedScheduleDisplay = null;
      _selectedTeacherId = null;
      _selectedTeacherName = null;
      _selectedSantris = [];
    });
    context.read<AddHalaqahCubit>().loadInitialData(gender);
  }

  void _handleSessionTap(BuildContext context, AddHalaqahState state) {
    if (_selectedGender == null) {
      _showSnack(context, 'Silakan pilih kategori kelas (Putra/Putri) terlebih dahulu');
      return;
    }

    if (state is AddHalaqahLoaded) {
      if (state.sessions.isEmpty) {
        _showSnack(context, 'Tidak ada data sesi tersedia');
        return;
      }
      
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Pilih Sesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.sessions.length,
                  itemBuilder: (ctx, index) {
                    final session = state.sessions[index];
                    return ListTile(
                      title: Text(FormatUtils.capitalize(session.name)),
                      onTap: () {
                         setState(() {
                           _selectedSessionId = session.id;
                           _selectedSessionName = FormatUtils.capitalize(session.name);
                           _selectedScheduleId = null;
                           _selectedScheduleDisplay = null;
                         });
                         context.read<AddHalaqahCubit>().loadSchedulesAndPeople(session.id, _selectedGender!);
                         Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
      );
    } else {
       _showSnack(context, 'Sedang memuat data...');
    }
  }



  Widget _buildDetailInfo(BuildContext context, AddHalaqahState state) {
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
        const SizedBox(height: 16),
        _buildScheduleInput(context, state),
      ],
    );
  }

  Widget _buildScheduleInput(BuildContext context, AddHalaqahState state) {
    return AiwaClickableInput(
      label: 'Jadwal',
      value: _selectedScheduleDisplay ?? 'Pilih Jadwal',
      icon: Icons.calendar_today,
      onTap: () {
        if (_selectedSessionId == null) {
          _showSnack(context, 'Silakan pilih sesi terlebih dahulu');
          return;
        }

        if (state is AddHalaqahLoaded) {
          if (state.schedules.isEmpty) {
             _showSnack(context, 'Tidak ada jadwal tersedia untuk sesi ini');
             return;
          }

          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) {
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
                        return ListTile(
                          title: Text(display),
                          onTap: () {
                             setState(() {
                               _selectedScheduleId = schedule.id;
                               _selectedScheduleDisplay = display;
                               _selectedTeacherId = null;
                               _selectedTeacherName = null;
                               _selectedSantris.clear();
                             });
                             context.read<AddHalaqahCubit>().checkScheduleAvailability(schedule.id);
                             Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
          );
        } else {
             _showSnack(context, 'Jadwal belum dimuat');
        }
      },
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
          'Pengajar (Asatidz)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AiwaClickableInput(
          label: 'Pengajar', 
          value: _selectedTeacherName ?? 'Pilih Pengajar', 
          icon: Icons.person_outline, 
          onTap: () async {
            if (_selectedGender == null) {
              _showSnack(context, 'Silakan pilih kategori kelas terlebih dahulu');
              return;
            }
            if (_selectedScheduleId == null) {
               _showSnack(context, 'Silakan pilih jadwal terlebih dahulu');
               return;
            }

            final unavailable = (state is AddHalaqahLoaded) ? state.unavailableTeacherIds : <String>[];

            final result = await context.pushNamed(
              RouteNames.selectAsatidz,
              extra: {
                'gender': _selectedGender,
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

  Widget _buildSantriSection(BuildContext context, AddHalaqahState state) {
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
            if (_selectedGender == null) {
              _showSnack(context, 'Silakan pilih kategori kelas terlebih dahulu');
              return;
            }
            if (_selectedScheduleId == null) {
               _showSnack(context, 'Silakan pilih jadwal terlebih dahulu');
               return;
            }

            final initialEntities = _selectedSantris.map((h) => SantriEntity(
              id: h.id, 
              name: h.name, 
              nis: '', 
              jenisKelamin: _selectedGender!, 
              isActive: true, 
              kelas: '', 
              isFree: false, 
              nomorWali: '', 
              pembimbing: ''
            )).toList();

            final unavailable = (state is AddHalaqahLoaded) ? state.unavailableSantriIds : <String>[];

            final result = await context.pushNamed(
              RouteNames.selectSantri,
              extra: {
                'gender': _selectedGender,
                'initialSelection': initialEntities,
                'disabledIds': unavailable,
              },
            );

            if (result != null && result is List<SantriEntity>) {
              setState(() {
                _selectedSantris = result.map((e) => HalaqahSantri(id: e.id, name: e.name)).toList();
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
    final names = _selectedSantris.map((e) => e.name).take(3).join(', ');
    if (_selectedSantris.length > 3) {
      return '$names, +${_selectedSantris.length - 3} lainnya';
    }
    return names;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: state is AddHalaqahLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Simpan Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _submit() {
    if (_selectedGender == null) {
      _showSnack(context, 'Pilih kategori kelas terlebih dahulu');
      return;
    }

    if (_selectedSessionId == null) {
      _showSnack(context, 'Pilih sesi terlebih dahulu');
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_selectedScheduleId == null) {
      _showSnack(context, 'Pilih jadwal terlebih dahulu');
      return;
    }

    if (_selectedTeacherId == null) {
      _showSnack(context, 'Pilih pengajar terlebih dahulu');
      return;
    }

    if (_selectedSantris.isEmpty) {
      _showSnack(context, 'Pilih minimal satu santri');
      return;
    }

    final halaqah = Halaqah(
      id: '',
      programId: _selectedSessionId!,
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
  
  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
