import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar pembuka + setelan kuis: pilih juz, sambungan antar surah, lalu mulai.
class QuizIntroView extends StatefulWidget {
  /// Dipanggil saat santri menekan "Mulai Kuis" dengan setelan terpilih.
  final ValueChanged<QuizSettings> onStart;

  /// Energi terkini; null bila belum dimuat. Dipakai untuk mengunci tombol
  /// mulai saat energi habis.
  final QuizEnergy? energy;

  /// True selama energi masih dimuat — tombol mulai dinonaktifkan.
  final bool energyLoading;

  const QuizIntroView({
    super.key,
    required this.onStart,
    this.energy,
    this.energyLoading = false,
  });

  @override
  State<QuizIntroView> createState() => _QuizIntroViewState();
}

class _QuizIntroViewState extends State<QuizIntroView> {
  final Set<int> _juz = {29, 30};
  bool _crossSurah = true;

  static const _juzInfo = <int, ({String range})>{
    29: (range: 'Al-Mulk — Al-Mursalat'),
    30: (range: 'An-Naba\' — An-Nas'),
  };

  void _toggleJuz(int juz, VoidCallback rebuild) {
    if (_juz.contains(juz)) {
      if (_juz.length == 1) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Minimal satu juz harus dipilih.'),
            duration: Duration(seconds: 2),
          ));
        return;
      }
      _juz.remove(juz);
    } else {
      _juz.add(juz);
    }
    rebuild();
  }

  String get _juzText {
    final sorted = _juz.toList()..sort();
    if (sorted.length == 2) return 'Juz 29 & 30';
    final j = sorted.first;
    return 'Juz $j (${_juzInfo[j]!.range})';
  }

  String get _settingsSummary =>
      '$_juzText · ${_crossSurah ? 'sambungan antar surah aktif' : 'tanpa sambungan antar surah'}';

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _SettingsSheet(
          juz: _juz,
          crossSurah: _crossSurah,
          juzInfo: _juzInfo,
          onToggleJuz: (j) => _toggleJuz(j, () => setSheet(() {})),
          onCrossSurah: (v) => setSheet(() => _crossSurah = v),
        ),
      ),
    );
    if (mounted) setState(() {}); // segarkan ringkasan pengaturan
  }

  Widget _buildStartButton() {
    final loading = widget.energyLoading && widget.energy == null;
    final canPlay = !loading && (widget.energy?.canPlay ?? true);

    final String label;
    final IconData icon;
    if (loading) {
      label = 'Memuat energi…';
      icon = Icons.hourglass_empty_rounded;
    } else if (!canPlay) {
      label = 'Energi habis';
      icon = Icons.hourglass_bottom_rounded;
    } else {
      label = 'Mulai Kuis';
      icon = Icons.play_arrow_rounded;
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canPlay
            ? () => widget.onStart(
                  QuizSettings(juz: {..._juz}, crossSurah: _crossSurah),
                )
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          scheme.primary.withValues(alpha: 0.7)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: QuizColors.gold, size: 48),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kuis Hafalan',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Uji hafalanmu dengan suara',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Ringkasan pengaturan (detail disimpan di bottom sheet).
                  _SettingsOverview(
                    summary: _settingsSummary,
                    onTap: _openSettings,
                  ),
                  const SizedBox(height: 24),

                  // Ringkasan aturan.
                  const _RuleTile(
                    icon: Icons.menu_book_rounded,
                    title: '10 soal acak',
                    subtitle: 'Sebuah ayat ditampilkan, lanjutkan 1-3 ayat.',
                  ),
                  const _RuleTile(
                    icon: Icons.mic_rounded,
                    title: 'Rekam suaramu',
                    subtitle: 'Bukan pilihan ganda — bacakan lanjutannya.',
                  ),
                  const _RuleTile(
                    icon: Icons.verified_rounded,
                    title: 'Nilai otomatis',
                    subtitle: '≥80% lanjut. <80% boleh mengulang sekali.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: _buildStartButton(),
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkasan pengaturan di layar depan; diketuk untuk membuka setelan.
class _SettingsOverview extends StatelessWidget {
  final String summary;
  final VoidCallback onTap;

  const _SettingsOverview({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune_rounded, color: scheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengaturan Kuis',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(summary,
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('Atur',
                style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Icon(Icons.chevron_right_rounded, color: scheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Isi bottom sheet pengaturan: pilih juz + setelan soal.
class _SettingsSheet extends StatelessWidget {
  final Set<int> juz;
  final bool crossSurah;
  final Map<int, ({String range})> juzInfo;
  final ValueChanged<int> onToggleJuz;
  final ValueChanged<bool> onCrossSurah;

  const _SettingsSheet({
    required this.juz,
    required this.crossSurah,
    required this.juzInfo,
    required this.onToggleJuz,
    required this.onCrossSurah,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan Kuis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _SectionLabel(icon: Icons.layers_rounded, text: 'Pilih Juz'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final j in const [29, 30]) ...[
                  if (j != 29) const SizedBox(width: 12),
                  Expanded(
                    child: _JuzOption(
                      juz: j,
                      range: juzInfo[j]!.range,
                      selected: juz.contains(j),
                      onTap: () => onToggleJuz(j),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            _SectionLabel(icon: Icons.tune_rounded, text: 'Setelan Soal'),
            const SizedBox(height: 10),
            _SwitchCard(
              icon: Icons.link_rounded,
              title: 'Sambungan antar surah',
              subtitle:
                  'Sesekali lanjut ke awal surah berikutnya (dengan basmalah).',
              value: crossSurah,
              onChanged: onCrossSurah,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Selesai',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Kartu pilihan juz (dapat dicentang), gaya selaras tema.
class _JuzOption extends StatelessWidget {
  final int juz;
  final String range;
  final bool selected;
  final VoidCallback onTap;

  const _JuzOption({
    required this.juz,
    required this.range,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : Colors.black26;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : Colors.black12,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Juz $juz',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: selected ? scheme.primary : Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              range,
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu setelan dengan switch di kanan.
class _SwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black54)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12.5, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
