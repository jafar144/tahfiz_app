import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

/// Detail seorang pengajar beserta seluruh halaqah/sesi yang diampunya.
/// Tiap halaqah menampilkan info sesi, jadwal, dan daftar santrinya.
class AsatidzHalaqahDetailPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String gender; // 'L' / 'P'

  const AsatidzHalaqahDetailPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.gender,
  });

  @override
  State<AsatidzHalaqahDetailPage> createState() =>
      _AsatidzHalaqahDetailPageState();
}

class _AsatidzHalaqahDetailPageState extends State<AsatidzHalaqahDetailPage> {
  final _repo = getIt<ScheduleRepository>();

  bool _loading = true;
  String? _error;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Halaqah> _halaqahs = [];
  final Map<String, ScheduleProgram> _programById = {};
  final Map<String, ProgramSchedule> _scheduleById = {};
  final Map<String, List<SantriEntity>> _santriByHalaqah = {};

  bool get _isMale => widget.gender == 'L';
  Color get _accent => _isMale ? Colors.blue : Colors.pink;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Program (sesi) untuk gender ini → untuk menamai sesi tiap halaqah.
      final programsRes = await _repo.getPrograms(gender: widget.gender);
      _programById.clear();
      programsRes.fold(
        ifLeft: (f) => throw Exception(f.message),
        ifRight: (programs) {
          for (final p in programs) {
            _programById[p.id] = p;
          }
        },
      );

      // Halaqah milik pengajar ini, dibatasi pada gender yang sedang dibuka.
      final halaqahRes = await _repo.getHalaqahsByTeacher(widget.teacherId);
      List<Halaqah> halaqahs = [];
      halaqahRes.fold(
        ifLeft: (f) => throw Exception(f.message),
        ifRight: (list) => halaqahs =
            list.where((h) => _programById.containsKey(h.programId)).toList(),
      );

      // Jadwal tiap program & santri tiap halaqah.
      _scheduleById.clear();
      _santriByHalaqah.clear();
      final loadedPrograms = <String>{};
      for (final h in halaqahs) {
        if (!loadedPrograms.contains(h.programId)) {
          loadedPrograms.add(h.programId);
          final schRes = await _repo.getSchedules(programId: h.programId);
          schRes.fold(
            ifLeft: (_) {},
            ifRight: (schedules) {
              for (final s in schedules) {
                _scheduleById[s.id] = s;
              }
            },
          );
        }

        final santriRes = await _repo.getSantrisByHalaqahId(h.id);
        santriRes.fold(
          ifLeft: (_) => _santriByHalaqah[h.id] = [],
          ifRight: (santris) => _santriByHalaqah[h.id] = santris,
        );
      }

      // Urutkan halaqah berdasarkan sesi (pagi → sore → malam) lalu nama.
      halaqahs.sort((a, b) {
        final sa = _sessionName(a).toLowerCase();
        final sb = _sessionName(b).toLowerCase();
        final order = {'pagi': 0, 'sore': 1, 'malam': 2};
        final bySession =
            (order[sa] ?? 99).compareTo(order[sb] ?? 99);
        if (bySession != 0) return bySession;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _halaqahs = halaqahs;
        _loading = false;
        if (_currentPage >= _halaqahs.length) {
          _currentPage = _halaqahs.isEmpty ? 0 : _halaqahs.length - 1;
        }
      });
      // Setelah jumlah halaqah berubah (mis. balik dari Kelola), pastikan
      // posisi pager tetap valid.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients &&
            _halaqahs.length > 1 &&
            _pageController.page?.round() != _currentPage) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _sessionName(Halaqah h) {
    final p = _programById[h.programId];
    final name = (p?.name.isNotEmpty ?? false) ? p!.name : 'Regular';
    return _capitalize(name);
  }

  int get _totalSantri =>
      _santriByHalaqah.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text(
          'Detail Pengajar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat data:\n$_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Satu halaqah (atau kosong) → cukup scroll vertikal biasa.
    if (_halaqahs.length <= 1) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            if (_halaqahs.isEmpty)
              _buildEmpty()
            else
              _buildHalaqahSection(_halaqahs.first),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Lebih dari satu halaqah → geser ke kanan antar halaqah (per sesi).
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildHeaderCard(),
        ),
        const SizedBox(height: 12),
        _buildHalaqahTabs(),
        const SizedBox(height: 4),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _halaqahs.length,
            itemBuilder: (context, index) {
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [_buildHalaqahSection(_halaqahs[index])],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab sesi untuk berpindah antar halaqah seorang pengajar.
  Widget _buildHalaqahTabs() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _halaqahs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final session = _sessionName(_halaqahs[index]);
          final selected = index == _currentPage;
          final color = _getSessionColor(session);
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getSessionIcon(session),
                      size: 14,
                      color: selected ? color : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    session,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              UiUtils.getInitials(widget.teacherName),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _accent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacherName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip(Icons.groups_2_rounded,
                        '${_halaqahs.length} Halaqah'),
                    _statChip(Icons.people_alt_rounded, '$_totalSantri Santri'),
                    _statChip(
                      Icons.person,
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

  Widget _statChip(IconData icon, String text, {Color? color}) {
    final c = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Belum ada halaqah untuk pengajar ini',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHalaqahSection(Halaqah halaqah) {
    final session = _sessionName(halaqah);
    final santriList = _santriByHalaqah[halaqah.id] ?? [];
    final schedules = halaqah.scheduleIds
        .map((id) => _scheduleById[id])
        .whereType<ProgramSchedule>()
        .toList()
      ..sort((a, b) {
        final byDay = a.day.compareTo(b.day);
        if (byDay != 0) return byDay;
        return a.startTime.compareTo(b.startTime);
      });

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu info halaqah.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _sessionBadge(session),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openManage(halaqah, session),
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Kelola'),
                      style: TextButton.styleFrom(
                        foregroundColor: _accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  halaqah.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.door_sliding_outlined,
                        size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Ruang ${halaqah.room}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (schedules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: schedules
                        .map((s) => _scheduleChip(
                            '${_dayName(s.day)} · ${s.startTime}-${s.endTime}'))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Header daftar santri.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  'Daftar Santri',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${santriList.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (santriList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Belum ada santri di halaqah ini',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else
            ...santriList.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SantriCard(s, showPembimbing: false),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openManage(Halaqah halaqah, String session) async {
    await context.pushNamed(
      RouteNames.detailHalaqah,
      extra: {
        'halaqah': halaqah,
        'sessionName': session,
        'gender': widget.gender,
      },
    );
    if (mounted) _load();
  }

  Widget _sessionBadge(String session) {
    final color = _getSessionColor(session);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSessionIcon(session), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            session,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getSessionColor(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Colors.orange.shade700;
      case 'sore':
        return Colors.deepOrange.shade700;
      case 'malam':
        return Colors.indigo.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getSessionIcon(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Icons.wb_sunny_outlined;
      case 'sore':
        return Icons.wb_twilight;
      case 'malam':
        return Icons.nights_stay_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _dayName(int day) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }
}
