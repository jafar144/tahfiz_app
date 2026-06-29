import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/utils/format_utils.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

/// Bottom sheet untuk mengganti pembimbing santri. Karena pembimbing terikat
/// lewat halaqah, mengganti pembimbing = memindahkan santri ke halaqah milik
/// asatidz lain (gender sama). Bila asatidz tujuan mengajar di lebih dari satu
/// halaqah (mis. sesi sore & malam), admin memilih halaqah/sesi mana dulu.
///
/// Mengembalikan `true` lewat `Navigator.pop` bila santri berhasil dipindahkan.
class SwitchPembimbingSheet extends StatefulWidget {
  final String santriId;
  final String santriName;
  final String santriGender; // 'L' / 'P'

  const SwitchPembimbingSheet({
    super.key,
    required this.santriId,
    required this.santriName,
    required this.santriGender,
  });

  @override
  State<SwitchPembimbingSheet> createState() => _SwitchPembimbingSheetState();
}

class _SwitchPembimbingSheetState extends State<SwitchPembimbingSheet> {
  final _scheduleRepo = getIt<ScheduleRepository>();
  final _santriRepo = getIt<SantriRepository>();

  bool _loading = true;
  String? _error;
  String? _currentTeacherId;
  List<AsatidzEntity> _asatidz = [];

  // Tahap pemilihan halaqah (saat asatidz mengajar di >1 halaqah).
  AsatidzEntity? _selectedAsatidz;
  bool _loadingHalaqah = false;
  List<Halaqah> _halaqahs = [];
  final Map<String, String> _sessionByHalaqah = {}; // halaqahId -> sesi

  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Halaqah saat ini → untuk tahu pembimbing lama (dikecualikan dari daftar).
      final halaqahRes =
          await _scheduleRepo.getHalaqahBySantriId(widget.santriId);
      halaqahRes.fold(
        ifLeft: (_) {},
        ifRight: (h) => _currentTeacherId = h?.teacherId,
      );

      // Kumpulkan id asatidz yang punya minimal satu halaqah aktif. Asatidz
      // tanpa halaqah tidak ditampilkan (tidak ada tujuan pindah).
      final halaqahsRes = await _scheduleRepo.getAllHalaqahs();
      final teachersWithHalaqah = <String>{};
      halaqahsRes.fold(
        ifLeft: (_) {},
        ifRight: (list) {
          for (final h in list) {
            if (h.status == 'Active' && h.teacherId.isNotEmpty) {
              teachersWithHalaqah.add(h.teacherId);
            }
          }
        },
      );

      final all = await _santriRepo.getAsatidzList();
      final filtered = all
          .where((a) =>
              a.isActive &&
              a.jenisKelamin == widget.santriGender &&
              a.id != _currentTeacherId &&
              teachersWithHalaqah.contains(a.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _asatidz = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectAsatidz(AsatidzEntity asatidz) async {
    setState(() {
      _selectedAsatidz = asatidz;
      _loadingHalaqah = true;
      _halaqahs = [];
      _sessionByHalaqah.clear();
    });

    final result = await _scheduleRepo.getHalaqahsByTeacher(asatidz.id);
    List<Halaqah> halaqahs = [];
    String? err;
    result.fold(
      ifLeft: (f) => err = f.message,
      ifRight: (list) =>
          halaqahs = list.where((h) => h.status == 'Active').toList(),
    );

    if (err != null) {
      if (!mounted) return;
      setState(() {
        _loadingHalaqah = false;
        _selectedAsatidz = null;
      });
      _snack('Gagal memuat halaqah: $err');
      return;
    }

    // Resolusi nama sesi tiap halaqah (untuk ditampilkan & disimpan ke tipe_kelas).
    for (final h in halaqahs) {
      final pres = await _scheduleRepo.getProgramById(h.programId);
      pres.fold(
        ifLeft: (_) {},
        ifRight: (p) => _sessionByHalaqah[h.id] = FormatUtils.capitalize(p.name),
      );
    }

    if (!mounted) return;

    if (halaqahs.isEmpty) {
      setState(() {
        _loadingHalaqah = false;
        _selectedAsatidz = null;
      });
      _snack('${asatidz.name} belum punya halaqah aktif');
      return;
    }

    if (halaqahs.length == 1) {
      setState(() => _loadingHalaqah = false);
      await _move(halaqahs.first);
      return;
    }

    setState(() {
      _halaqahs = halaqahs;
      _loadingHalaqah = false;
    });
  }

  Future<void> _move(Halaqah halaqah) async {
    setState(() => _moving = true);
    final result = await _scheduleRepo.moveSantriToHalaqah(
      widget.santriId,
      halaqah.id,
      newSession: _sessionByHalaqah[halaqah.id],
    );
    if (!mounted) return;
    setState(() => _moving = false);
    result.fold(
      ifLeft: (f) => _snack('Gagal memindahkan: ${f.message}'),
      ifRight: (_) => Navigator.of(context).pop(true),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inHalaqahStep = _selectedAsatidz != null && _halaqahs.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            8,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildHeader(inHalaqahStep),
            const Divider(height: 1),
            Flexible(child: _buildBody(inHalaqahStep)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool inHalaqahStep) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          if (inHalaqahStep)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: _moving
                  ? null
                  : () => setState(() {
                        _selectedAsatidz = null;
                        _halaqahs = [];
                      }),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inHalaqahStep ? 'Pilih Halaqah / Sesi' : 'Ganti Pembimbing',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  inHalaqahStep
                      ? '${_selectedAsatidz!.name} mengajar di beberapa halaqah'
                      : 'Pindahkan ${widget.santriName} ke pembimbing lain',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool inHalaqahStep) {
    if (_moving) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildMessage('Gagal memuat data asatidz.\n$_error');
    }

    if (inHalaqahStep) {
      return _buildHalaqahList();
    }

    if (_loadingHalaqah) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_asatidz.isEmpty) {
      return _buildMessage(
        'Tidak ada asatidz lain dengan jenis kelamin yang sesuai.',
      );
    }

    return _buildAsatidzList();
  }

  Widget _buildMessage(String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildAsatidzList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _asatidz.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _asatidz[index];
        return _buildTile(
          initials: UiUtils.getInitials(a.name),
          title: a.name,
          subtitle: 'NIS ${a.nis}',
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _selectAsatidz(a),
        );
      },
    );
  }

  Widget _buildHalaqahList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _halaqahs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final h = _halaqahs[index];
        final session = _sessionByHalaqah[h.id];
        final subtitleParts = <String>[
          if (session != null && session.isNotEmpty) 'Sesi $session',
          if (h.room.isNotEmpty) 'Ruang ${h.room}',
          '${h.santriCount} santri',
        ];
        return _buildTile(
          icon: Icons.groups_2_rounded,
          title: h.name.isNotEmpty ? h.name : 'Halaqah',
          subtitle: subtitleParts.join(' • '),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _move(h),
        );
      },
    );
  }

  Widget _buildTile({
    String? initials,
    IconData? icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade50,
              child: icon != null
                  ? Icon(icon, color: Colors.blue.shade700, size: 20)
                  : Text(
                      initials ?? '?',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
