import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/session_spin/data/session_spin_loader.dart';
import 'package:khoirunnasyien/features/session_spin/domain/session_spin.dart';
import 'package:khoirunnasyien/features/session_spin/presentation/widgets/session_spin_wheel.dart';

class SessionSpinPage extends StatefulWidget {
  final String teacherId;
  final SessionSpinLoader? loader;
  final Future<SessionSpinCatalog> Function(String teacherId)? catalogLoader;
  final Random? random;
  final Duration spinDuration;

  const SessionSpinPage({
    super.key,
    required this.teacherId,
    this.loader,
    this.catalogLoader,
    this.random,
    this.spinDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<SessionSpinPage> createState() => _SessionSpinPageState();
}

class _SessionSpinPageState extends State<SessionSpinPage> {
  late final SessionSpinLoader? _loader;
  late final Random _random;

  SessionSpinCatalog? _catalog;
  String? _selectedHalaqahId;
  Set<String> _selectedIds = {};
  SessionSpin _session = SessionSpin(const []);
  SantriEntity? _latestWinner;
  bool _loading = true;
  bool _spinning = false;
  String? _error;
  double _wheelTurns = 0;

  SessionSpinHalaqah? get _selectedHalaqah {
    final catalog = _catalog;
    if (catalog == null || catalog.halaqahs.isEmpty) return null;
    return catalog.halaqahs.firstWhere(
      (item) => item.halaqah.id == _selectedHalaqahId,
      orElse: () => catalog.halaqahs.first,
    );
  }

  bool get _selectionLocked => _spinning || _session.order.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loader =
        widget.loader ??
        (widget.catalogLoader == null
            ? SessionSpinLoader(
                scheduleRepository: getIt<ScheduleRepository>(),
                asatidzRepository: getIt<AsatidzRepository>(),
              )
            : null);
    _random = widget.random ?? Random();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog =
          await (widget.catalogLoader?.call(widget.teacherId) ??
              _loader!.load(widget.teacherId));
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
        _selectHalaqahState(
          catalog.halaqahs.isEmpty ? null : catalog.halaqahs.first.halaqah.id,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  void _selectHalaqahState(String? halaqahId) {
    _selectedHalaqahId = halaqahId;
    final halaqah = _catalog?.halaqahs
        .where((item) => item.halaqah.id == halaqahId)
        .firstOrNull;
    final participants = halaqah?.participants ?? const <SantriEntity>[];
    _selectedIds = participants.map((item) => item.id).toSet();
    _session = SessionSpin(participants);
    _latestWinner = null;
    _wheelTurns = 0;
  }

  void _changeHalaqah(String? halaqahId) {
    if (_selectionLocked || halaqahId == null) return;
    setState(() => _selectHalaqahState(halaqahId));
  }

  void _updateParticipants(Set<String> selectedIds) {
    if (_selectionLocked) return;
    final halaqah = _selectedHalaqah;
    if (halaqah == null) return;
    final participants = halaqah.participants
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);
    setState(() {
      _selectedIds = selectedIds;
      _session = SessionSpin(participants);
      _latestWinner = null;
    });
  }

  void _toggleParticipant(SantriEntity santri, bool selected) {
    final updated = Set<String>.from(_selectedIds);
    selected ? updated.add(santri.id) : updated.remove(santri.id);
    _updateParticipants(updated);
  }

  void _toggleAll(bool selected) {
    final participants = _selectedHalaqah?.participants ?? const [];
    _updateParticipants(
      selected ? participants.map((item) => item.id).toSet() : <String>{},
    );
  }

  Future<void> _spin() async {
    if (_spinning || _session.remaining.isEmpty) return;
    setState(() {
      _spinning = true;
      _wheelTurns += 5 + _random.nextDouble() * 2;
    });
    await Future<void>.delayed(widget.spinDuration);
    if (!mounted) return;
    final winner = _session.drawNext(_random);
    setState(() {
      _latestWinner = winner;
      _spinning = false;
    });
  }

  Future<void> _reset() async {
    if (_spinning || _session.order.isEmpty) return;
    final confirmed = await showAiwaActionSheet<bool>(
      context: context,
      title: 'Reset Hasil Spin?',
      content: const Text(
        'Urutan yang sudah keluar akan dikosongkan. Checklist peserta tetap '
        'dipertahankan agar sesi dapat diulang.',
        style: TextStyle(height: 1.45),
      ),
      confirmText: 'Reset Hasil',
      confirmValue: true,
      cancelValue: false,
      confirmColor: Colors.red,
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _session.resetOrder();
      _latestWinner = null;
      _wheelTurns = 0;
    });
  }

  Future<void> _copyResult() async {
    final halaqah = _selectedHalaqah;
    if (halaqah == null || _session.order.isEmpty) return;
    final lines = <String>[
      'Urutan sesi ${halaqah.halaqah.name}',
      for (var index = 0; index < _session.order.length; index++)
        '${index + 1}. ${_session.order[index].name}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hasil urutan disalin.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: const AiwaAppBar(title: 'Spin Urutan Santri'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final catalog = _catalog!;
    if (catalog.halaqahs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Belum ada halaqah aktif yang dapat dipakai untuk sesi spin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final selectedHalaqah = _selectedHalaqah!;
    return RefreshIndicator(
      onRefresh: _selectionLocked ? () async {} : _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildHalaqahPicker(catalog, selectedHalaqah),
          const SizedBox(height: 14),
          _buildParticipants(selectedHalaqah),
          const SizedBox(height: 18),
          _buildSpinArea(),
          if (_session.order.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildHalaqahPicker(
    SessionSpinCatalog catalog,
    SessionSpinHalaqah selected,
  ) {
    final genderLabel = catalog.teacherGender == 'L' ? 'Putra' : 'Putri';
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halaqah Sesi',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey('spin-halaqah-$_selectedHalaqahId'),
              initialValue: _selectedHalaqahId,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
              items: [
                for (final item in catalog.halaqahs)
                  DropdownMenuItem(
                    value: item.halaqah.id,
                    child: Text(
                      '${item.halaqah.name} • ${item.isOwn ? "Halaqah saya" : "Sesama $genderLabel"}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _selectionLocked ? null : _changeHalaqah,
            ),
            const SizedBox(height: 8),
            Text(
              selected.isOwn
                  ? 'Peserta berasal dari halaqah Anda.'
                  : 'Halaqah lain dibatasi untuk pengajar dan santri $genderLabel.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants(SessionSpinHalaqah selected) {
    final participants = selected.participants;
    final allSelected =
        participants.isNotEmpty && _selectedIds.length == participants.length;
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CheckboxListTile(
              key: const ValueKey('spin-select-all'),
              value: allSelected,
              onChanged: _selectionLocked
                  ? null
                  : (value) => _toggleAll(value ?? false),
              title: const Text(
                'Checklist Peserta',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _selectionLocked
                    ? 'Reset hasil untuk mengubah peserta.'
                    : '${_selectedIds.length} dari ${participants.length} santri dipilih',
              ),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            const Divider(height: 1),
            if (participants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Belum ada santri aktif di halaqah ini.'),
              )
            else
              for (final santri in participants)
                CheckboxListTile(
                  key: ValueKey('spin-participant-${santri.id}'),
                  value: _selectedIds.contains(santri.id),
                  onChanged: _selectionLocked
                      ? null
                      : (value) => _toggleParticipant(santri, value ?? false),
                  title: Text(santri.name),
                  subtitle: Text('NIS ${santri.nis} • ${santri.kelas}'),
                  secondary: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      santri.name.trim().isEmpty
                          ? '?'
                          : santri.name.trim()[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinArea() {
    final isComplete = _session.isComplete;
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SessionSpinWheel(
              turns: _wheelTurns,
              duration: widget.spinDuration,
              isSpinning: _spinning,
              winnerName: _latestWinner?.name,
              remainingCount: _session.remaining.length,
            ),
            const SizedBox(height: 4),
            AiwaButton(
              key: const ValueKey('spin-next-button'),
              text: isComplete ? 'Urutan Selesai' : 'Spin Berikutnya',
              onPressed: _spinning || _session.remaining.isEmpty ? null : _spin,
              isLoading: _spinning,
            ),
            if (_selectedIds.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Pilih minimal satu peserta untuk memulai.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hasil Sesi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin hasil',
                  onPressed: _copyResult,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const Divider(),
            for (var index = 0; index < _session.order.length; index++)
              ListTile(
                key: ValueKey('spin-result-${_session.order[index].id}'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.orange.shade100
                      : Colors.blue.shade50,
                  child: Text('${index + 1}'),
                ),
                title: Text(_session.order[index].name),
                subtitle: Text(_session.order[index].kelas),
              ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const ValueKey('spin-reset-button'),
              onPressed: _spinning ? null : _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Hasil'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
