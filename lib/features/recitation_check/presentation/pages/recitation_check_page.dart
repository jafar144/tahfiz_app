import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_cubit.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_state.dart';

class RecitationCheckPage extends StatelessWidget {
  const RecitationCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uji Bacaan Qur\'an')),
      body: BlocBuilder<RecitationCheckCubit, RecitationCheckState>(
        builder: (context, state) {
          if (state.status == RecitationStatus.loadingSurah ||
              (state.status == RecitationStatus.initial)) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TargetSelector(),
                const SizedBox(height: 16),
                const _AyatPreview(),
                const SizedBox(height: 24),
                const _RecordControl(),
                if (state.status == RecitationStatus.error) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage ?? 'Terjadi kesalahan.'),
                ],
                if (state.status == RecitationStatus.done && state.result != null) ...[
                  const SizedBox(height: 24),
                  _ResultView(result: state.result!, ayat: state.checkedAyat),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TargetSelector extends StatelessWidget {
  const _TargetSelector();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationCheckCubit>();
    final state = context.watch<RecitationCheckCubit>().state;
    final surah = state.selectedSurah;
    final maxAyah = surah?.totalVerses ?? 1;
    final busy = state.isBusy || state.status == RecitationStatus.recording;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Target setoran', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<SurahInfo>(
              initialValue: surah,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Surah',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in state.surahs)
                  DropdownMenuItem(
                    value: s,
                    child: Text('${s.id}. ${s.latin}'),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (s) {
                      if (s != null) cubit.selectSurah(s);
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AyahDropdown(
                    label: 'Dari ayat',
                    value: state.fromAyah,
                    max: maxAyah,
                    enabled: !busy,
                    onChanged: cubit.setFrom,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AyahDropdown(
                    label: 'Sampai ayat',
                    value: state.toAyah,
                    max: maxAyah,
                    enabled: !busy,
                    onChanged: cubit.setTo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahDropdown extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _AyahDropdown({
    required this.label,
    required this.value,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value > max ? max : value;
    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (var n = 1; n <= max; n++)
          DropdownMenuItem(value: n, child: Text('$n')),
      ],
      onChanged: enabled
          ? (v) {
              if (v != null) onChanged(v);
            }
          : null,
    );
  }
}

class _AyatPreview extends StatelessWidget {
  const _AyatPreview();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecitationCheckCubit>().state;
    final surah = state.selectedSurah;
    if (surah == null) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${surah.latin} • ayat ${state.fromAyah}-${state.toAyah}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol mikrofon lalu baca ayat di atas. Tekan lagi untuk berhenti & periksa.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordControl extends StatelessWidget {
  const _RecordControl();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationCheckCubit>();
    final state = context.watch<RecitationCheckCubit>().state;
    final isRecording = state.status == RecitationStatus.recording;
    final isProcessing = state.status == RecitationStatus.processing;

    if (isProcessing) {
      return Column(
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Memproses bacaan…'),
        ],
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: isRecording ? cubit.stopAndCheck : cubit.startRecording,
          child: CircleAvatar(
            radius: 44,
            backgroundColor: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
            child: Icon(
              isRecording ? Icons.stop : Icons.mic,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(isRecording ? 'Sedang merekam… ketuk untuk berhenti' : 'Ketuk untuk mulai membaca'),
        if (isRecording)
          TextButton(
            onPressed: cubit.cancelRecording,
            child: const Text('Batal'),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final RecitationResult result;
  final List<Ayah> ayat;

  const _ResultView({required this.result, required this.ayat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${result.accuracyPercent}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _scoreColor(result.accuracy),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Kata benar dari total ayat target')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip('Benar', result.correctCount, Colors.green),
                _CountChip('Salah', result.wrongCount, Colors.orange),
                _CountChip('Kelewat', result.missingCount, Colors.red),
                _CountChip('Tambahan', result.extraCount, Colors.blueGrey),
              ],
            ),
            const Divider(height: 24),
            const Text('Analisis per kata', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text(
              'Teks dari mushaf (tanpa harakat); warna = hasil banding dengan suaramu. '
              'Panjang-pendek (mad/tajwid) belum dinilai di tahap ini.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in result.diffs) _WordChip(diff: d),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Teks mentah hasil transkripsi'),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      result.transcription,
                      style: const TextStyle(fontSize: 18, height: 1.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _Legend(),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(double acc) {
    if (acc >= 0.9) return Colors.green;
    if (acc >= 0.7) return Colors.orange;
    return Colors.red;
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      label: Text('$label: $count', style: TextStyle(color: color)),
    );
  }
}

class _WordChip extends StatelessWidget {
  final WordDiff diff;
  const _WordChip({required this.diff});

  @override
  Widget build(BuildContext context) {
    final color = switch (diff.status) {
      WordStatus.correct => Colors.green,
      WordStatus.wrong => Colors.orange,
      WordStatus.missing => Colors.red,
      WordStatus.extra => Colors.blueGrey,
    };
    final text = diff.status == WordStatus.extra
        ? (diff.spokenWord ?? '')
        : (diff.referenceWord ?? '');
    final decoration = diff.status == WordStatus.missing
        ? TextDecoration.lineThrough
        : (diff.status == WordStatus.extra ? TextDecoration.underline : null);

    // Untuk kata salah, tampilkan juga apa yang terdengar (dari suara) agar jelas
    // ini perbandingan suara vs mushaf, bukan tebakan acak.
    final showHeard = diff.status == WordStatus.wrong &&
        diff.spokenWord != null &&
        diff.spokenWord!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              height: 1.6,
              color: color,
              decoration: decoration,
            ),
          ),
          if (showHeard)
            Text(
              'terdengar: ${diff.spokenWord}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: const [
        _LegendItem(color: Colors.green, label: 'Benar'),
        _LegendItem(color: Colors.orange, label: 'Salah baca'),
        _LegendItem(color: Colors.red, label: 'Kelewat (coret)'),
        _LegendItem(color: Colors.blueGrey, label: 'Tambahan (garis bawah)'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
