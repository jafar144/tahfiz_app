import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

class AsatidzHalaqahDetailPage extends StatefulWidget {
  final String teacherId;

  /// Fallback untuk deep-link/route versi lama. Nama terbaru tetap diambil dari
  /// `asatidz_profiles` menggunakan [teacherId].
  final String teacherName;
  final String gender;
  final ScheduleRepository? scheduleRepository;
  final AsatidzRepository? asatidzRepository;

  const AsatidzHalaqahDetailPage({
    super.key,
    required this.teacherId,
    this.teacherName = '-',
    required this.gender,
    this.scheduleRepository,
    this.asatidzRepository,
  });

  @override
  State<AsatidzHalaqahDetailPage> createState() =>
      _AsatidzHalaqahDetailPageState();
}

class _AsatidzHalaqahDetailPageState extends State<AsatidzHalaqahDetailPage> {
  late final ScheduleRepository _scheduleRepository;
  late final AsatidzRepository _asatidzRepository;

  bool _loading = true;
  String? _error;
  AsatidzDetail? _teacher;
  List<Halaqah> _halaqahs = [];
  final Map<String, ScheduleProgram> _programById = {};
  final Map<String, ProgramSchedule> _scheduleById = {};
  final Map<String, List<SantriEntity>> _santriByHalaqah = {};
  String? _selectedHalaqahId;
  int _loadRevision = 0;

  bool get _isMale => widget.gender == 'L';
  Color get _accent => _isMale ? Colors.blue : Colors.pink;
  String get _teacherName {
    final current = _teacher?.name.trim();
    if (current != null && current.isNotEmpty) return current;
    final hydrated = _halaqahs.isEmpty
        ? ''
        : _halaqahs.first.teacherName.trim();
    if (hydrated.isNotEmpty) return hydrated;
    final fallback = widget.teacherName.trim();
    return fallback.isEmpty || fallback == '-' ? 'Pengajar' : fallback;
  }

  Halaqah? get _selectedHalaqah {
    if (_halaqahs.isEmpty) return null;
    return _halaqahs.firstWhere(
      (halaqah) => halaqah.id == _selectedHalaqahId,
      orElse: () => _halaqahs.first,
    );
  }

  int get _totalSantri =>
      _santriByHalaqah.values.fold(0, (sum, list) => sum + list.length);

  @override
  void initState() {
    super.initState();
    _scheduleRepository =
        widget.scheduleRepository ?? getIt<ScheduleRepository>();
    _asatidzRepository = widget.asatidzRepository ?? getIt<AsatidzRepository>();
    _load();
  }

  Future<void> _load() async {
    final revision = ++_loadRevision;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      Future<AsatidzDetail?> loadTeacher() async {
        try {
          return await _asatidzRepository.getAsatidzDetail(widget.teacherId);
        } catch (_) {
          return null;
        }
      }

      Future<List<ScheduleProgram>> loadPrograms() async {
        try {
          final result = await _scheduleRepository.getPrograms(
            gender: widget.gender,
          );
          var programs = <ScheduleProgram>[];
          result.fold(
            ifLeft: (_) {},
            ifRight: (items) => programs = List<ScheduleProgram>.from(items),
          );
          return programs;
        } catch (_) {
          return <ScheduleProgram>[];
        }
      }

      Future<List<Halaqah>> loadHalaqahs() async {
        final result = await _scheduleRepository.getHalaqahsByTeacher(
          widget.teacherId,
        );
        var halaqahs = <Halaqah>[];
        String? errorMessage;
        result.fold(
          ifLeft: (failure) => errorMessage = failure.message,
          ifRight: (items) => halaqahs = List<Halaqah>.from(items),
        );
        if (errorMessage != null) throw Exception(errorMessage);
        return halaqahs;
      }

      // Ketiga data inti dimulai bersamaan. Nama/program bersifat best-effort,
      // sedangkan daftar halaqah adalah satu-satunya data yang wajib berhasil.
      final teacherFuture = loadTeacher();
      final programsFuture = loadPrograms();
      final halaqahsFuture = loadHalaqahs();
      final teacher = await teacherFuture;
      final programs = await programsFuture;
      final halaqahs = await halaqahsFuture;
      final programById = <String, ScheduleProgram>{
        for (final program in programs) program.id: program,
      };

      Future<void> hydrateMissingProgram(String programId) async {
        if (programId.trim().isEmpty || programById.containsKey(programId)) {
          return;
        }
        try {
          final result = await _scheduleRepository.getProgramById(programId);
          result.fold(
            ifLeft: (_) {},
            ifRight: (program) => programById[program.id] = program,
          );
        } catch (_) {
          // Dokumen sesi lama boleh hilang; detail tetap memakai fallback.
        }
      }

      await Future.wait(
        halaqahs
            .map((halaqah) => halaqah.programId)
            .toSet()
            .map(hydrateMissingProgram),
      );

      String sessionNameFor(Halaqah halaqah) {
        final rawName = programById[halaqah.programId]?.name.trim() ?? '';
        if (rawName.isEmpty) return 'Reguler';
        return rawName[0].toUpperCase() + rawName.substring(1);
      }

      halaqahs.sort((first, second) {
        final firstOrder = _sessionOrder(sessionNameFor(first));
        final secondOrder = _sessionOrder(sessionNameFor(second));
        final bySession = firstOrder.compareTo(secondOrder);
        if (bySession != 0) return bySession;
        final byRoom = first.room.toLowerCase().compareTo(
          second.room.toLowerCase(),
        );
        return byRoom != 0 ? byRoom : first.id.compareTo(second.id);
      });

      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _teacher = teacher;
        _programById
          ..clear()
          ..addAll(programById);
        _scheduleById.clear();
        _santriByHalaqah.clear();
        _halaqahs = halaqahs;
        if (_selectedHalaqahId == null ||
            !_halaqahs.any((item) => item.id == _selectedHalaqahId)) {
          _selectedHalaqahId = _halaqahs.isEmpty ? null : _halaqahs.first.id;
        }
        _loading = false;
      });

      // Jadwal dan anggota tidak menahan render halaman inti. Keduanya dimuat
      // paralel dan kegagalan salah satu child read tidak mengosongkan halaman.
      final scheduleById = <String, ProgramSchedule>{};
      final santriByHalaqah = <String, List<SantriEntity>>{};

      Future<void> loadSchedules(String programId) async {
        if (programId.trim().isEmpty) return;
        try {
          final result = await _scheduleRepository.getSchedules(
            programId: programId,
          );
          result.fold(
            ifLeft: (_) {},
            ifRight: (schedules) {
              for (final schedule in schedules) {
                scheduleById[schedule.id] = schedule;
              }
            },
          );
        } catch (_) {
          // Jadwal adalah data pelengkap; card sesi tetap dapat ditampilkan.
        }
      }

      Future<void> loadSantri(String halaqahId) async {
        try {
          final result = await _scheduleRepository.getSantrisByHalaqahId(
            halaqahId,
          );
          result.fold(
            ifLeft: (_) => santriByHalaqah[halaqahId] = [],
            ifRight: (santri) => santriByHalaqah[halaqahId] = santri,
          );
        } catch (_) {
          santriByHalaqah[halaqahId] = [];
        }
      }

      await Future.wait<void>([
        ...halaqahs
            .map((halaqah) => halaqah.programId)
            .toSet()
            .map(loadSchedules),
        ...halaqahs.map((halaqah) => loadSantri(halaqah.id)),
      ]);

      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _scheduleById
          ..clear()
          ..addAll(scheduleById);
        _santriByHalaqah
          ..clear()
          ..addAll(santriByHalaqah);
      });
    } catch (error) {
      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: const AiwaAppBar(title: 'Detail Pengajar'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 46,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _selectedHalaqah;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildSessionChips(),
          const SizedBox(height: 16),
          if (selected == null)
            _buildEmptyState()
          else
            _buildSessionSection(selected),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _accent.withValues(alpha: 0.1),
            backgroundImage: (_teacher?.photoUrl?.trim().isNotEmpty ?? false)
                ? NetworkImage(_teacher!.photoUrl!)
                : null,
            child: (_teacher?.photoUrl?.trim().isNotEmpty ?? false)
                ? null
                : Text(
                    UiUtils.getInitials(_teacherName),
                    style: TextStyle(
                      color: _accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teacherName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _statChip(
                      Icons.schedule_rounded,
                      '${_halaqahs.length} Sesi',
                    ),
                    _statChip(
                      Icons.people_alt_outlined,
                      '$_totalSantri Santri',
                    ),
                    _statChip(
                      _isMale ? Icons.male_rounded : Icons.female_rounded,
                      _isMale ? 'Putra' : 'Putri',
                      color: _accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final halaqah in _halaqahs) ...[
            _SessionChip(
              label: _sessionName(halaqah),
              icon: _sessionIcon(_sessionName(halaqah)),
              color: _sessionColor(_sessionName(halaqah)),
              selected: halaqah.id == _selectedHalaqahId,
              onTap: () => setState(() => _selectedHalaqahId = halaqah.id),
            ),
            const SizedBox(width: 8),
          ],
          _SessionChip(
            label: 'Tambah sesi',
            icon: Icons.add_rounded,
            color: Colors.blue,
            selected: false,
            dashedIntent: true,
            onTap: _openAddSession,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSection(Halaqah halaqah) {
    final session = _sessionName(halaqah);
    final santri = _santriByHalaqah[halaqah.id] ?? [];
    final schedules =
        halaqah.scheduleIds
            .map((id) => _scheduleById[id])
            .whereType<ProgramSchedule>()
            .toList()
          ..sort((first, second) {
            final byDay = first.day.compareTo(second.day);
            return byDay != 0
                ? byDay
                : first.startTime.compareTo(second.startTime);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sessionBadge(session),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _openEdit(halaqah),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade200),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Hapus sesi',
                    onPressed: () => _confirmDelete(halaqah, session),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      backgroundColor: Colors.red.shade50,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 17,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    halaqah.room.trim().isEmpty
                        ? 'Ruangan belum diatur'
                        : 'Ruang ${halaqah.room}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (schedules.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: schedules
                      .map(
                        (item) => _scheduleChip(
                          '${_dayName(item.day)} • '
                          '${item.startTime}–${item.endTime}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Daftar Santri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${santri.length}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (santri.isEmpty)
          _emptySantri()
        else
          for (final item in santri)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SantriCard(item, showPembimbing: false),
            ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 50,
            color: Colors.blue[200],
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada sesi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            'Tambahkan sesi pertama untuk pengajar ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openAddSession,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah sesi'),
          ),
        ],
      ),
    );
  }

  Widget _emptySantri() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Belum ada santri pada sesi ini',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, {Color? color}) {
    final foreground = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionBadge(String session) {
    final color = _sessionColor(session);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_sessionIcon(session), color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            'Sesi $session',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _openAddSession() async {
    await context.pushNamed(
      RouteNames.addHalaqah,
      extra: {
        'initialGender': widget.gender,
        'initialTeacherId': widget.teacherId,
      },
    );
    if (mounted) await _load();
  }

  Future<void> _openEdit(Halaqah halaqah) async {
    await context.pushNamed(RouteNames.editHalaqah, extra: halaqah);
    if (mounted) await _load();
  }

  Future<void> _confirmDelete(Halaqah halaqah, String session) async {
    final confirmed = await showAiwaActionSheet<bool>(
      context: context,
      title: 'Hapus sesi $session?',
      content: const Text(
        'Santri pada sesi ini akan dilepas dari halaqah. '
        'Tindakan ini tidak menghapus akun santri.',
      ),
      cancelText: 'Batal',
      confirmText: 'Hapus sesi',
      cancelValue: false,
      confirmValue: true,
      cancelColor: Colors.grey,
      confirmColor: Colors.red,
    );
    if (confirmed != true || !mounted) return;

    final result = await _scheduleRepository.deleteHalaqah(halaqah.id);
    if (!mounted) return;
    result.fold(
      ifLeft: (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      ifRight: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sesi berhasil dihapus')));
        _load();
      },
    );
  }

  String _sessionName(Halaqah halaqah) {
    final rawName = _programById[halaqah.programId]?.name.trim() ?? '';
    if (rawName.isEmpty) return 'Reguler';
    return rawName[0].toUpperCase() + rawName.substring(1);
  }

  int _sessionOrder(String session) => switch (session.toLowerCase()) {
    'pagi' => 0,
    'sore' => 1,
    'malam' => 2,
    _ => 99,
  };

  Color _sessionColor(String session) => switch (session.toLowerCase()) {
    'pagi' => Colors.orange.shade700,
    'sore' => Colors.deepOrange.shade700,
    'malam' => Colors.indigo.shade700,
    _ => Colors.blueGrey.shade700,
  };

  IconData _sessionIcon(String session) => switch (session.toLowerCase()) {
    'pagi' => Icons.wb_sunny_outlined,
    'sore' => Icons.wb_twilight_outlined,
    'malam' => Icons.nights_stay_outlined,
    _ => Icons.schedule_outlined,
  };

  String _dayName(int day) {
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
}

class _SessionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool dashedIntent;
  final VoidCallback onTap;

  const _SessionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    this.dashedIntent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.11) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected || dashedIntent ? color : Colors.grey.shade300,
              width: dashedIntent ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected || dashedIntent ? color : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected || dashedIntent
                      ? color
                      : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
