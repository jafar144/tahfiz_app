import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_energy_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';

/// Nilai default pemberian energi (samakan dengan default server).
const _kDefaultPractice = 15;
const _kDefaultChallenge = 2;

/// Halaman admin: beri energi kuis TAMBAHAN ke santri terpilih.
///
/// Energi tambahan berlaku untuk minggu berjalan saja — ikut hangus saat kuota
/// direset tiap Senin (dokumen mingguan baru). Default pemberian: +15 energi
/// latihan dan +2 energi Tantangan per mode; jumlahnya bisa disesuaikan di
/// lembar konfirmasi sebelum dikirim.
class AdminEnergyPage extends StatelessWidget {
  const AdminEnergyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Instance sendiri agar filter/pagination di sini tidak mengganggu
      // state daftar santri pada tab Santri.
      create: (_) => SantriCubit(getIt())..loadSantri(isActive: true),
      child: const _AdminEnergyView(),
    );
  }
}

class _AdminEnergyView extends StatefulWidget {
  const _AdminEnergyView();

  @override
  State<_AdminEnergyView> createState() => _AdminEnergyViewState();
}

class _AdminEnergyViewState extends State<_AdminEnergyView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<SantriCubit>().loadMoreSantri();
    }
  }

  void _onSearch() {
    UiUtils.unfocus(context);
    context.read<SantriCubit>().loadSantri(
      keyword: _searchController.text,
      isActive: true,
    );
  }

  Future<void> _openGrantSheet(SantriEntity santri) async {
    final result = await showModalBottomSheet<QuizEnergy>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GrantEnergySheet(santri: santri),
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Energi terkirim ke ${santri.name} — sekarang: latihan '
            '${result.current}/${result.max}, Tantangan Suara '
            '${result.challengeVoiceLeft}/${result.challengeVoiceMax}, '
            'Pilihan ${result.challengeChoiceLeft}/${result.challengeChoiceMax}.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AiwaAppBar(title: 'Beri Energi Kuis'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info singkat sistem kuota mingguan.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3DFB3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        size: 18,
                        color: Color(0xFFB9770B),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Energi tambahan berlaku untuk MINGGU BERJALAN dan '
                          'hangus saat kuota direset tiap Senin. Default: +15 '
                          'energi latihan, +2 Tantangan per mode.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF7A5A10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AiwaSearch(
                  controller: _searchController,
                  hintText: 'Cari nama santri…',
                  onSubmitted: (_) => _onSearch(),
                  onSearch: _onSearch,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SantriCubit, SantriState>(
              builder: (context, state) {
                switch (state) {
                  case SantriInitial() || SantriLoading():
                    return const Center(child: CircularProgressIndicator());
                  case SantriError(:final message):
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _onSearch,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  case SantriLoaded(
                    :final santri,
                    :final isFetchingMore,
                  ):
                    if (santri.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada santri yang cocok.'),
                      );
                    }
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: santri.length + (isFetchingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i >= santri.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _SantriTile(
                          santri: santri[i],
                          onTap: () => _openGrantSheet(santri[i]),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SantriTile extends StatelessWidget {
  final SantriEntity santri;
  final VoidCallback onTap;

  const _SantriTile({required this.santri, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFFFF1D6),
              backgroundImage: santri.photoUrl != null
                  ? NetworkImage(santri.photoUrl!)
                  : null,
              child: santri.photoUrl == null
                  ? Text(
                      santri.name.isNotEmpty
                          ? santri.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFFB9770B),
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    santri.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'NIS ${santri.nis} • ${santri.kelas}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.bolt_rounded,
              color: Color(0xFFB9770B),
              size: 20,
            ),
            Text(
              'Beri',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lembar konfirmasi pemberian energi: jumlah bisa disesuaikan lewat stepper,
/// lalu dikirim ke Cloud Function `grantQuizEnergy`.
class _GrantEnergySheet extends StatefulWidget {
  final SantriEntity santri;

  const _GrantEnergySheet({required this.santri});

  @override
  State<_GrantEnergySheet> createState() => _GrantEnergySheetState();
}

class _GrantEnergySheetState extends State<_GrantEnergySheet> {
  int _practice = _kDefaultPractice;
  int _challengeVoice = _kDefaultChallenge;
  int _challengeChoice = _kDefaultChallenge;

  bool _sending = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final energy = await getIt<QuizEnergyRemoteDataSource>().grantEnergy(
        uid: widget.santri.id,
        practice: _practice,
        challengeVoice: _challengeVoice,
        challengeChoice: _challengeChoice,
      );
      if (!mounted) return;
      Navigator.of(context).pop(energy);
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _sending = false;
        _error = e.message ?? 'Gagal mengirim energi.';
      });
    } catch (e) {
      setState(() {
        _sending = false;
        _error = 'Gagal mengirim energi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _practice + _challengeVoice + _challengeChoice;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFB9770B),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Beri Energi — ${widget.santri.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahan berlaku untuk minggu berjalan (hangus saat reset '
              'Senin).',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _StepperRow(
              icon: Icons.nightlight_round,
              label: 'Energi latihan',
              value: _practice,
              enabled: !_sending,
              onChanged: (v) => setState(() => _practice = v),
            ),
            const SizedBox(height: 10),
            _StepperRow(
              icon: Icons.mic_rounded,
              label: 'Tantangan — Suara',
              value: _challengeVoice,
              enabled: !_sending,
              onChanged: (v) => setState(() => _challengeVoice = v),
            ),
            const SizedBox(height: 10),
            _StepperRow(
              icon: Icons.grid_view_rounded,
              label: 'Tantangan — Pilihan',
              value: _challengeChoice,
              enabled: !_sending,
              onChanged: (v) => setState(() => _challengeChoice = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12.5, color: Colors.red),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB9770B),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: _sending || total <= 0 ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_sending ? 'Mengirim…' : 'Kirim Energi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris pengatur jumlah: label + tombol −/+ dengan nilai di tengah.
class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  static const _max = 50;

  const _StepperRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFB9770B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: enabled && value < _max
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
