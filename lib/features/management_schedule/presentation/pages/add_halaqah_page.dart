import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/utils/format_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_state.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';

class AddHalaqahPage extends StatefulWidget {
  final String? initialGender;
  final String? initialTeacherId;

  const AddHalaqahPage({super.key, this.initialGender, this.initialTeacherId});

  @override
  State<AddHalaqahPage> createState() => _AddHalaqahPageState();
}

class _AddHalaqahPageState extends State<AddHalaqahPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomController = TextEditingController();

  String? _selectedGender;
  String? _selectedSessionId;
  String? _selectedSessionName;
  List<String> _selectedScheduleIds = [];
  String? _selectedTeacherId;
  String? _selectedTeacherName;

  List<SantriEntity> _selectedSantris = [];

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
    _selectedTeacherId = widget.initialTeacherId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = context.read<AddHalaqahCubit>();
      final gender = _selectedGender;
      if (gender != null) {
        await cubit.loadInitialData(gender);
      }
      final teacherId = _selectedTeacherId;
      if (teacherId != null) {
        try {
          final detail = await cubit.getAsatidzDetail(teacherId);
          if (mounted) setState(() => _selectedTeacherName = detail.name);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: const AiwaAppBar(title: 'Tambah Sesi Halaqah'),
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
                text: 'Simpan Sesi',
                onPressed: state is AddHalaqahLoading ? null : _submit,
                isLoading: state is AddHalaqahLoading,
                height: 50,
              ),
            ),
          ),
          body: SafeArea(
            child: Form(
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
                    const SizedBox(height: 24),
                  ],
                ),
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
        const AiwaFormSectionTitle(title: 'Kategori Santri'),
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
        ),
      ],
    );
  }

  void _updateGender(BuildContext context, String gender) {
    if (_selectedGender == gender) return;
    setState(() {
      _selectedGender = gender;
      _selectedSessionId = null;
      _selectedSessionName = null;
      _selectedScheduleIds = [];
      _selectedTeacherId = null;
      _selectedTeacherName = null;
      _selectedSantris = [];
    });
    context.read<AddHalaqahCubit>().loadInitialData(gender);
  }

  Future<void> _handleSessionTap(
    BuildContext context,
    AddHalaqahState state,
  ) async {
    if (_selectedGender == null) {
      _showSnack(
        context,
        'Silakan pilih kategori kelas (Putra/Putri) terlebih dahulu',
      );
      return;
    }

    if (state is! AddHalaqahLoaded) {
      _showSnack(context, 'Sedang memuat data...');
      return;
    }
    if (state.sessions.isEmpty) {
      _showSnack(context, 'Tidak ada data sesi tersedia');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHeader(
                  title: 'Pilih Sesi',
                  subtitle: 'Pilih program waktu untuk halaqah baru.',
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.sessions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 68),
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      final sessionName = FormatUtils.capitalize(session.name);
                      final selected = session.id == _selectedSessionId;
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _sessionIcon(sessionName),
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Sesi $sessionName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Colors.blue.shade700,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.black38,
                              ),
                        onTap: () {
                          setState(() {
                            _selectedSessionId = session.id;
                            _selectedSessionName = sessionName;
                            _selectedScheduleIds = [];
                          });
                          context
                              .read<AddHalaqahCubit>()
                              .loadSchedulesAndPeople(
                                session.id,
                                _selectedGender!,
                              );
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailInfo(BuildContext context, AddHalaqahState state) {
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
        _buildScheduleInput(context, state),
      ],
    );
  }

  Widget _buildScheduleInput(BuildContext context, AddHalaqahState state) {
    final schedules = state is AddHalaqahLoaded
        ? state.schedules
        : <ProgramSchedule>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiwaClickableInput(
          label: 'Jadwal Pertemuan',
          value: _selectedScheduleIds.isEmpty
              ? 'Pilih jadwal'
              : '${_selectedScheduleIds.length} jadwal dipilih',
          icon: Icons.calendar_month_outlined,
          onTap: () async {
            if (_selectedSessionId == null) {
              _showSnack(context, 'Silakan pilih sesi terlebih dahulu');
              return;
            }
            if (schedules.isEmpty) {
              _showSnack(context, 'Jadwal belum dimuat');
              return;
            }
            await _showSchedulePicker(schedules);
          },
        ),
        if (_selectedScheduleIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedScheduleIds.map((id) {
              final schedule = _findSchedule(schedules, id);
              return InputChip(
                label: Text(
                  schedule == null
                      ? 'Jadwal tidak ditemukan'
                      : _scheduleLabel(schedule),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                avatar: Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: Colors.blue.shade700,
                ),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade100),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
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
                    const _SheetHeader(
                      title: 'Pilih Jadwal',
                      subtitle: 'Anda dapat memilih lebih dari satu jadwal.',
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
                                selected
                                    ? draft.remove(schedule.id)
                                    : draft.add(schedule.id);
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
                          if (_selectedScheduleIds.isNotEmpty) {
                            context
                                .read<AddHalaqahCubit>()
                                .checkScheduleAvailability(
                                  _selectedScheduleIds.first,
                                );
                          }
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

  IconData _sessionIcon(String session) => switch (session.toLowerCase()) {
    'pagi' => Icons.wb_sunny_outlined,
    'sore' => Icons.wb_twilight_outlined,
    'malam' => Icons.nights_stay_outlined,
    _ => Icons.schedule_outlined,
  };

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

  Widget _buildPengajarSection(BuildContext context, AddHalaqahState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiwaFormSectionTitle(title: 'Pengajar'),
        const SizedBox(height: 12),
        AiwaClickableInput(
          label: 'Pengajar',
          value: _selectedTeacherName ?? 'Pilih Pengajar',
          icon: Icons.person_outline,
          onTap: () async {
            if (_selectedGender == null) {
              _showSnack(
                context,
                'Silakan pilih kategori kelas terlebih dahulu',
              );
              return;
            }
            final unavailable = (state is AddHalaqahLoaded)
                ? state.unavailableTeacherIds
                : <String>[];

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
            const AiwaFormSectionTitle(title: 'Santri'),
            if (_selectedSantris.isNotEmpty)
              Text(
                '${_selectedSantris.length} dipilih',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AiwaClickableInput(
          label: 'Anggota Halaqah',
          value: _selectedSantris.isEmpty
              ? 'Pilih santri'
              : _selectSantrisPreview(),
          icon: Icons.groups_2_outlined,
          onTap: () async {
            if (_selectedGender == null) {
              _showSnack(
                context,
                'Silakan pilih kategori kelas terlebih dahulu',
              );
              return;
            }
            final initialEntities = List<SantriEntity>.from(_selectedSantris);

            final unavailable = (state is AddHalaqahLoaded)
                ? state.unavailableSantriIds
                : <String>[];

            final result = await context.pushNamed(
              RouteNames.selectSantri,
              extra: {
                'gender': _selectedGender,
                'initialSelection': initialEntities,
                'disabledIds': unavailable,
                'isMultiSelect': true,
                'allowHalaqahTransfer': true,
                'currentHalaqahId': null,
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
              final willMove = santri.halaqahId?.trim().isNotEmpty == true;
              final color = willMove
                  ? Colors.orange.shade800
                  : Colors.blue.shade700;
              return InputChip(
                label: Text(
                  santri.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                avatar: Icon(
                  willMove
                      ? Icons.swap_horiz_rounded
                      : Icons.person_outline_rounded,
                  size: 15,
                  color: color,
                ),
                backgroundColor: willMove
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                side: BorderSide(
                  color: willMove
                      ? Colors.orange.shade200
                      : Colors.blue.shade100,
                ),
                deleteIcon: Icon(Icons.close_rounded, size: 16, color: color),
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

    if (_selectedScheduleIds.isEmpty) {
      _showSnack(context, 'Pilih minimal satu jadwal terlebih dahulu');
      return;
    }

    if (_selectedTeacherId == null ||
        _selectedTeacherName == null ||
        _selectedTeacherName!.trim().isEmpty) {
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
      scheduleIds: _selectedScheduleIds,
      name: 'Sesi ${_selectedSessionName!}',
      room: _roomController.text.trim(),
      teacherId: _selectedTeacherId!,
      teacherName: _selectedTeacherName!,
      status: 'Active',
    );

    final santriIds = _selectedSantris.map((s) => s.id).toList();
    context.read<AddHalaqahCubit>().createHalaqah(halaqah, santriIds);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SheetHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
