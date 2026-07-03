import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar pembuka + setelan kuis: pilih mode, juz, rentang target hafalan, lalu
/// mulai. Setelan dipegang oleh cubit (dan disimpan lokal) — layar ini hanya
/// menampilkan [settings] terkini dan mengirim perubahan lewat [onSettingsChanged].
class QuizIntroView extends StatelessWidget {
  /// Setelan terkini (sumber kebenaran = cubit).
  final QuizSettings settings;

  /// Dipanggil tiap setelan berubah (mode/juz/rentang) untuk disimpan.
  final ValueChanged<QuizSettings> onSettingsChanged;

  /// Dipanggil saat santri menekan "Mulai Kuis".
  final ValueChanged<QuizSettings> onStart;

  /// Energi terkini; null bila belum dimuat. Dipakai untuk mengunci tombol
  /// mulai saat energi habis.
  final QuizEnergy? energy;

  /// True selama energi masih dimuat — tombol mulai dinonaktifkan.
  final bool energyLoading;

  const QuizIntroView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onStart,
    this.energy,
    this.energyLoading = false,
  });

  String get _juzSummary {
    final sorted = settings.sortedJuz;
    final parts = sorted.map((j) {
      final start = settings.startSurahFor(j);
      return start == QuizJuz.firstSurah(j)
          ? 'Juz $j'
          : 'Juz $j (${QuizJuz.rangeLabel(j, start)})';
    });
    return parts.join(' · ');
  }

  String get _settingsSummary => 'Mode ${settings.mode.label} · $_juzSummary';

  Future<void> _openSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SettingsSheet(
        initial: settings,
        onChanged: onSettingsChanged,
      ),
    );
  }

  Widget _buildStartButton() {
    final isChoice = settings.mode.isChoice;
    final loading = !isChoice && energyLoading && energy == null;
    // Mode pilihan tak memakai energi → selalu bisa mulai.
    final canPlay = isChoice || (!loading && (energy?.canPlay ?? true));

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
        onPressed: canPlay ? () => onStart(settings) : null,
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

  /// Tiga aturan ringkas yang menyesuaikan mode.
  List<Widget> _rulesFor(QuizMode mode) {
    if (mode.isChoice) {
      return const [
        _RuleTile(
          icon: Icons.grid_view_rounded,
          title: 'Pilihan ganda 6 opsi',
          subtitle: 'Pilih lanjutan ayat yang benar — 1 sampai 3 ayat berurutan.',
        ),
        _RuleTile(
          icon: Icons.timer_rounded,
          title: 'Adu cepat 60 detik',
          subtitle: 'Jawab sebanyak-banyaknya sebelum waktu habis.',
        ),
        _RuleTile(
          icon: Icons.bolt_rounded,
          title: 'Benar = poin, tanpa energi',
          subtitle: '10 poin (1 ayat), 15 (2 ayat), 20 (3 ayat). Energi tidak terpakai.',
        ),
      ];
    }
    return const [
      _RuleTile(
        icon: Icons.menu_book_rounded,
        title: '10 soal acak',
        subtitle: 'Sebuah ayat ditampilkan, lanjutkan 1-3 ayat.',
      ),
      _RuleTile(
        icon: Icons.mic_rounded,
        title: 'Rekam suaramu',
        subtitle: 'Bukan pilihan ganda — bacakan lanjutannya.',
      ),
      _RuleTile(
        icon: Icons.verified_rounded,
        title: 'Nilai otomatis',
        subtitle: '≥80% lanjut. <80% boleh mengulang sekali.',
      ),
    ];
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
                  Text(
                    settings.mode.isChoice
                        ? 'Uji hafalanmu dengan pilihan ganda'
                        : 'Uji hafalanmu dengan suara',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Ringkasan pengaturan (detail disimpan di bottom sheet).
                  _SettingsOverview(
                    summary: _settingsSummary,
                    onTap: () => _openSettings(context),
                  ),
                  const SizedBox(height: 24),

                  // Ringkasan aturan (menyesuaikan mode).
                  ..._rulesFor(settings.mode),
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

/// Isi bottom sheet pengaturan: pilih mode + juz + rentang target hafalan.
/// Menyimpan salinan kerja lokal & mengabarkan tiap perubahan lewat [onChanged].
class _SettingsSheet extends StatefulWidget {
  final QuizSettings initial;
  final ValueChanged<QuizSettings> onChanged;

  const _SettingsSheet({required this.initial, required this.onChanged});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late QuizSettings _s = widget.initial;

  void _update(QuizSettings next) {
    setState(() => _s = next);
    widget.onChanged(next);
  }

  void _toggleJuz(int j) {
    final juz = {..._s.juz};
    if (juz.contains(j)) {
      if (juz.length == 1) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Minimal satu juz harus dipilih.'),
            duration: Duration(seconds: 2),
          ));
        return;
      }
      juz.remove(j);
    } else {
      juz.add(j);
    }
    _update(_s.copyWith(juz: juz));
  }

  @override
  Widget build(BuildContext context) {
    final selectedJuz = _s.sortedJuz;
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
            const _SectionLabel(
                icon: Icons.sports_esports_rounded, text: 'Mode Main'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ModeOption(
                    icon: Icons.mic_rounded,
                    title: 'Suara',
                    subtitle: 'Bacakan lanjutannya',
                    selected: _s.mode.isVoice,
                    onTap: () => _update(_s.copyWith(mode: QuizMode.voice)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeOption(
                    icon: Icons.grid_view_rounded,
                    title: 'Pilihan',
                    subtitle: '6 opsi · 60 detik',
                    selected: _s.mode.isChoice,
                    onTap: () => _update(_s.copyWith(mode: QuizMode.choice)),
                  ),
                ),
              ],
            ),
            if (_s.mode.isChoice) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mode pilihan tidak memakai energi.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const _SectionLabel(icon: Icons.layers_rounded, text: 'Pilih Juz'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final j in QuizJuz.supported) ...[
                  if (j != QuizJuz.supported.first) const SizedBox(width: 12),
                  Expanded(
                    child: _JuzOption(
                      juz: j,
                      range:
                          '${QuizJuz.nameOf(QuizJuz.firstSurah(j))} — ${QuizJuz.nameOf(QuizJuz.lastSurah(j))}',
                      selected: _s.juz.contains(j),
                      onTap: () => _toggleJuz(j),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel(
                icon: Icons.flag_rounded, text: 'Rentang Target Hafalan'),
            const SizedBox(height: 4),
            const Text(
              'Atur surah awal yang kamu hafal. Surah terakhir tiap juz dikunci '
              'sebagai ujung target.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            for (final j in selectedJuz) ...[
              _RangeTargetCard(
                juz: j,
                startSurah: _s.startSurahFor(j),
                onStartChanged: (s) => _update(_s.withRangeStart(j, s)),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
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

/// Kartu pemilihan mode main (Suara / Pilihan).
class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                Icon(icon,
                    size: 20,
                    color: selected ? scheme.primary : Colors.black45),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: selected ? scheme.primary : Colors.black26,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: selected ? scheme.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ],
        ),
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

/// Kartu pengaturan rentang target hafalan satu juz: dropdown surah awal +
/// surah terakhir juz yang dikunci.
class _RangeTargetCard extends StatelessWidget {
  final int juz;
  final int startSurah;
  final ValueChanged<int> onStartChanged;

  const _RangeTargetCard({
    required this.juz,
    required this.startSurah,
    required this.onStartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surahs = QuizJuz.surahsOf(juz);
    final lastSurah = QuizJuz.lastSurah(juz);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Juz $juz',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Surah awal (bisa dipilih).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dari surah',
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          isDense: true,
                          value: startSurah,
                          borderRadius: BorderRadius.circular(12),
                          items: [
                            for (final s in surahs)
                              DropdownMenuItem<int>(
                                value: s,
                                child: Text(
                                  QuizJuz.nameOf(s),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) onStartChanged(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.black38),
              ),
              // Surah akhir (dikunci).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hingga surah',
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              QuizJuz.nameOf(lastSurah),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(Icons.lock_rounded,
                              size: 15, color: Colors.black38),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
