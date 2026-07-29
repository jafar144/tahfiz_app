import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_state.dart';

class EditHalaqahPage extends StatefulWidget {
  const EditHalaqahPage({super.key});

  @override
  State<EditHalaqahPage> createState() => _EditHalaqahPageState();
}

class _EditHalaqahPageState extends State<EditHalaqahPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();

  bool _didPopulate = false;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  String _status = 'Active';
  List<SantriEntity> _selectedSantris = [];
  List<String> _selectedScheduleIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HalaqahDetailCubit>().init();
    });
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _populateData(HalaqahDetailLoaded state) {
    if (_didPopulate) return;

    final halaqah = state.halaqah;
    _didPopulate = true;
    _roomController.text = halaqah.room;
    _selectedTeacherId = halaqah.teacherId;
    _selectedTeacherName = halaqah.teacherName;
    _status = halaqah.status;
    _selectedSantris = List<SantriEntity>.from(state.santriList);
    _selectedScheduleIds = List<String>.from(halaqah.scheduleIds);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HalaqahDetailCubit, HalaqahDetailState>(
      listener: (context, state) {
        if (state is HalaqahDetailLoaded) {
          _populateData(state);
        } else if (state is HalaqahDetailSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi halaqah berhasil diperbarui')),
          );
          context.pop(true);
        } else if (state is HalaqahDetailError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is HalaqahDetailLoading ||
            state is HalaqahDetailInitial ||
            state is HalaqahDetailUpdating) {
          return const Scaffold(
            appBar: AiwaAppBar(title: 'Edit Sesi Halaqah'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is! HalaqahDetailLoaded) {
          return const Scaffold(
            appBar: AiwaAppBar(title: 'Edit Sesi Halaqah'),
            body: Center(child: Text('Data halaqah tidak ditemukan')),
          );
        }

        _populateData(state);
        return _buildForm(state);
      },
    );
  }

  Widget _buildForm(HalaqahDetailLoaded state) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: const AiwaAppBar(title: 'Edit Sesi Halaqah'),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: AiwaButton(
            text: 'Simpan Perubahan',
            onPressed: state.isSubmitting ? null : () => _submit(state),
            isLoading: state.isSubmitting,
            height: 50,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _buildSessionSummary(state),
              const SizedBox(height: 24),
              _buildDetailSection(state),
              const SizedBox(height: 24),
              _buildTeacherSection(state),
              const SizedBox(height: 24),
              _buildSantriSection(state),
              const SizedBox(height: 24),
              _buildStatusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSummary(HalaqahDetailLoaded state) {
    final genderLabel = state.gender == 'P' ? 'Putri' : 'Putra';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_stories_outlined, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengaturan sesi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$genderLabel • ${_selectedSantris.length} santri',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiwaFormSectionTitle(title: 'Detail Sesi'),
        const SizedBox(height: 12),
        AiwaTextField(
          label: 'Ruangan',
          hint: 'Masukkan nama ruangan',
          icon: Icons.meeting_room_outlined,
          controller: _roomController,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        AiwaClickableInput(
          label: 'Jadwal Pertemuan',
          value: _selectedScheduleIds.isEmpty
              ? 'Pilih jadwal'
              : '${_selectedScheduleIds.length} jadwal dipilih',
          icon: Icons.calendar_month_outlined,
          onTap: () => _showSchedulePicker(state.schedules),
        ),
        if (_selectedScheduleIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedScheduleIds.map((id) {
              final schedule = _findSchedule(state.schedules, id);
              return _SelectedValueChip(
                label: schedule == null
                    ? 'Jadwal tidak ditemukan'
                    : _scheduleLabel(schedule),
                icon: Icons.schedule_rounded,
                onDeleted: () {
                  setState(() => _selectedScheduleIds.remove(id));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _showSchedulePicker(List<ProgramSchedule> schedules) async {
    if (schedules.isEmpty) {
      _showMessage('Belum ada jadwal yang tersedia untuk sesi ini');
      return;
    }

    final draft = Set<String>.from(_selectedScheduleIds);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Jadwal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Anda dapat memilih lebih dari satu jadwal.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: schedules.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 68),
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          final selected = draft.contains(schedule.id);
                          return CheckboxListTile(
                            value: selected,
                            activeColor: Colors.blue,
                            controlAffinity: ListTileControlAffinity.trailing,
                            secondary: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.event_available_outlined,
                                size: 20,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            title: Text(
                              _getDayName(schedule.day),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${schedule.startTime} – ${schedule.endTime}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onChanged: (_) {
                              setSheetState(() {
                                if (selected) {
                                  draft.remove(schedule.id);
                                } else {
                                  draft.add(schedule.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: AiwaButton(
                        text: 'Terapkan (${draft.length})',
                        onPressed: () {
                          setState(() {
                            _selectedScheduleIds = schedules
                                .where((item) => draft.contains(item.id))
                                .map((item) => item.id)
                                .toList();
                          });
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeacherSection(HalaqahDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiwaFormSectionTitle(title: 'Pengajar'),
        const SizedBox(height: 12),
        AiwaClickableInput(
          label: 'Pengajar',
          value: _selectedTeacherName ?? 'Pilih pengajar',
          icon: Icons.person_outline_rounded,
          onTap: () async {
            final result = await context.pushNamed(
              RouteNames.selectAsatidz,
              extra: {
                'gender': state.gender.isEmpty ? null : state.gender,
                'initialSelectedId': _selectedTeacherId,
                'disabledIds': state.unavailableTeacherIds,
              },
            );

            if (result is AsatidzEntity && mounted) {
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
          children: [
            const AiwaFormSectionTitle(title: 'Santri'),
            const Spacer(),
            if (_selectedSantris.isNotEmpty)
              _CountBadge(count: _selectedSantris.length),
          ],
        ),
        const SizedBox(height: 12),
        AiwaClickableInput(
          label: 'Anggota Halaqah',
          value: _selectedSantris.isEmpty ? 'Pilih santri' : _santriPreview(),
          icon: Icons.groups_2_outlined,
          onTap: () async {
            final result = await context.pushNamed(
              RouteNames.selectSantri,
              extra: {
                'gender': state.gender.isEmpty ? null : state.gender,
                'initialSelection': List<SantriEntity>.from(_selectedSantris),
                'disabledIds': state.unavailableSantriIds,
                'isMultiSelect': true,
                'allowHalaqahTransfer': true,
                'currentHalaqahId': state.halaqah.id,
              },
            );

            if (result is List<SantriEntity> && mounted) {
              setState(() => _selectedSantris = result);
            }
          },
        ),
        if (_selectedSantris.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSantris.map((santri) {
              final sourceHalaqahId = santri.halaqahId?.trim();
              final willMove =
                  sourceHalaqahId != null &&
                  sourceHalaqahId.isNotEmpty &&
                  sourceHalaqahId != state.halaqah.id;
              return _SelectedValueChip(
                label: santri.name,
                icon: willMove
                    ? Icons.swap_horiz_rounded
                    : Icons.person_outline_rounded,
                warning: willMove,
                onDeleted: () {
                  setState(() {
                    _selectedSantris.removeWhere(
                      (item) => item.id == santri.id,
                    );
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Santri dari halaqah lain baru dipindahkan setelah perubahan disimpan.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiwaFormSectionTitle(title: 'Status'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AiwaSelectionCard(
                label: 'Aktif',
                icon: Icons.check_circle_outline_rounded,
                isSelected: _status == 'Active',
                activeColor: Colors.green,
                onTap: () => setState(() => _status = 'Active'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AiwaSelectionCard(
                label: 'Nonaktif',
                icon: Icons.pause_circle_outline_rounded,
                isSelected: _status != 'Active',
                activeColor: Colors.red,
                onTap: () => setState(() => _status = 'Non-Active'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submit(HalaqahDetailLoaded state) {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedScheduleIds.isEmpty) {
      _showMessage('Pilih minimal satu jadwal');
      return;
    }
    if (_selectedTeacherId == null || _selectedTeacherId!.trim().isEmpty) {
      _showMessage('Pilih pengajar terlebih dahulu');
      return;
    }
    if (_selectedSantris.isEmpty) {
      _showMessage('Pilih minimal satu santri');
      return;
    }

    final current = state.halaqah;
    final updated = Halaqah(
      id: current.id,
      programId: current.programId,
      scheduleIds: List<String>.from(_selectedScheduleIds),
      // Dipertahankan untuk kompatibilitas dokumen lama, tetapi tidak lagi
      // ditampilkan maupun dapat diedit dari UI.
      name: current.name,
      room: _roomController.text.trim(),
      teacherId: _selectedTeacherId!,
      teacherName: _selectedTeacherName ?? current.teacherName,
      status: _status,
    );
    final finalSantriIds = _selectedSantris.map((item) => item.id).toList();
    context.read<HalaqahDetailCubit>().updateHalaqah(updated, finalSantriIds);
  }

  ProgramSchedule? _findSchedule(List<ProgramSchedule> schedules, String id) {
    for (final schedule in schedules) {
      if (schedule.id == id) return schedule;
    }
    return null;
  }

  String _scheduleLabel(ProgramSchedule schedule) {
    return '${_getDayName(schedule.day)}, '
        '${schedule.startTime}–${schedule.endTime}';
  }

  String _getDayName(int day) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return day >= 1 && day <= 7 ? days[day - 1] : '-';
  }

  String _santriPreview() {
    final names = _selectedSantris.map((item) => item.name).take(3).join(', ');
    final remainder = _selectedSantris.length - 3;
    return remainder > 0 ? '$names, +$remainder lainnya' : names;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectedValueChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onDeleted;
  final bool warning;

  const _SelectedValueChip({
    required this.label,
    required this.icon,
    required this.onDeleted,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.orange.shade800 : Colors.blue.shade700;
    return InputChip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      avatar: Icon(icon, size: 15, color: color),
      deleteIcon: Icon(Icons.close_rounded, size: 16, color: color),
      onDeleted: onDeleted,
      backgroundColor: warning ? Colors.orange.shade50 : Colors.blue.shade50,
      side: BorderSide(
        color: warning ? Colors.orange.shade200 : Colors.blue.shade100,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count dipilih',
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
