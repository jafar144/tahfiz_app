import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_energy_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

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
  final bool embedded;

  const AdminEnergyPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Instance sendiri agar filter/pagination di sini tidak mengganggu
      // state daftar santri pada tab Santri.
      create: (_) => SantriCubit(getIt())..loadSantri(isActive: true),
      child: _AdminEnergyView(embedded: embedded),
    );
  }
}

class _AdminEnergyView extends StatefulWidget {
  final bool embedded;

  const _AdminEnergyView({required this.embedded});

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
      backgroundColor: QuizColors.nightCard,
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
    final content = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 14 : 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded) ...[
                const _ArenaEnergyHeader(),
                const SizedBox(height: 14),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: QuizColors.gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: QuizColors.gold.withValues(alpha: 0.34),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 18,
                      color: QuizColors.gold,
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
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearch(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari nama santri…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Cari',
                    onPressed: _onSearch,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: QuizColors.gold,
                    ),
                  ),
                  filled: true,
                  fillColor: QuizColors.nightCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: QuizColors.gold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<SantriCubit, SantriState>(
            builder: (context, state) {
              switch (state) {
                case SantriInitial() || SantriLoading() || SantriCreated():
                  return const Center(
                    child: CircularProgressIndicator(color: QuizColors.gold),
                  );
                case SantriError(:final message):
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: QuizColors.goldDark,
                            ),
                            onPressed: _onSearch,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                case SantriLoaded(:final santri, :final isFetchingMore):
                  if (santri.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada santri yang cocok.',
                        style: TextStyle(color: Colors.white54),
                      ),
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
                            child: CircularProgressIndicator(
                              color: QuizColors.gold,
                            ),
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
    );

    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: const Color(0xFF0B2540),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F35),
        foregroundColor: Colors.white,
        title: const Text('Energi Santri'),
      ),
      body: content,
    );
  }
}

class _ArenaEnergyHeader extends StatelessWidget {
  const _ArenaEnergyHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.bolt_rounded, size: 30, color: QuizColors.gold),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Energi Santri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Tambahkan bekal latihan dan tantangan',
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
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
          color: QuizColors.nightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: QuizColors.gold.withValues(alpha: 0.15),
              child: Text(
                santri.name.isNotEmpty ? santri.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: QuizColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'NIS ${santri.nis} • ${santri.kelas}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.bolt_rounded, color: QuizColors.gold, size: 20),
            Text(
              'Beri',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
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
                  color: QuizColors.gold,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Beri Energi — ${widget.santri.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
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
              style: const TextStyle(fontSize: 12, color: Colors.white54),
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
                  backgroundColor: QuizColors.goldDark,
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
        Icon(icon, size: 18, color: QuizColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: QuizColors.gold,
          disabledColor: Colors.white24,
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: enabled && value < _max
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          color: QuizColors.gold,
          disabledColor: Colors.white24,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
