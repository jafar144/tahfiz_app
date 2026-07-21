import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_cubit.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_state.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/widgets/mushaf_view.dart';

class RecitationCheckPage extends StatelessWidget {
  const RecitationCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecitationCheckCubit, RecitationCheckState>(
      listenWhen: (p, c) =>
          c.status == RecitationStatus.error &&
          c.errorMessage != null &&
          p.errorMessage != c.errorMessage,
      listener: (ctx, state) {
        ScaffoldMessenger.of(ctx)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const _TargetTitle()),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: const _BottomActions(),
        body: const _MushafBody(),
      ),
    );
  }
}

/// Judul AppBar = target setoran saat ini; diketuk untuk mengubah surah/ayat.
class _TargetTitle extends StatelessWidget {
  const _TargetTitle();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecitationCheckCubit>().state;
    final surah = state.selectedSurah;
    final title = surah?.latin ?? 'Pilih Surah';
    final busy = state.isBusy || state.status == RecitationStatus.recording;

    return InkWell(
      onTap: busy ? null : () => _openTargetSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ayat ${state.fromAyah}–${state.toAyah}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!busy) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

void _openTargetSheet(BuildContext context) {
  final cubit = context.read<RecitationCheckCubit>();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _TargetSheet()),
  );
}

class _TargetSheet extends StatelessWidget {
  const _TargetSheet();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationCheckCubit>();
    final state = context.watch<RecitationCheckCubit>().state;
    final surah = state.selectedSurah;
    final maxAyah = surah?.totalVerses ?? 1;
    final busy = state.isBusy || state.status == RecitationStatus.recording;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Setoran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai'),
              ),
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

/// Body: halaman-halaman mushaf yang bisa digeser kiri-kanan (satu layar
/// per halaman, tanpa scroll vertikal). Rentang ayat hanya menentukan bagian
/// yang diperiksa, bukan membatasi tampilan.
class _MushafBody extends StatefulWidget {
  const _MushafBody();

  @override
  State<_MushafBody> createState() => _MushafBodyState();
}

class _MushafBodyState extends State<_MushafBody> {
  final PageController _controller = PageController();
  String _signature = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecitationCheckCubit>().state;

    if (state.status == RecitationStatus.loadingSurah ||
        state.status == RecitationStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.pageAyat.isEmpty) {
      return const Center(child: Text('Pilih surah dan rentang ayat.'));
    }

    final pages = groupAyatByPage(state.pageAyat);
    final signature = pages.map((p) => p.page).join(',');
    if (signature != _signature) {
      _signature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) _controller.jumpToPage(0);
      });
    }

    final coloredWords =
        (state.status == RecitationStatus.done && state.result != null)
        ? buildTargetColoring(state.targetAyat, state.result!)
        : null;

    // reverse: true -> geser dari kanan ke kiri seperti membaca mushaf.
    return PageView.builder(
      controller: _controller,
      reverse: true,
      itemCount: pages.length,
      itemBuilder: (context, i) => MushafView(
        ayat: pages[i].ayat,
        targetSurahId: state.selectedSurah?.id ?? 0,
        fromAyah: state.fromAyah,
        toAyah: state.toAyah,
        coloredWords: coloredWords,
      ),
    );
  }
}

/// Tombol mengambang: [lihat hasil] + [rekam], berdampingan.
class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecitationCheckCubit>().state;
    final showResult =
        state.status == RecitationStatus.done && state.result != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showResult) ...[
          FloatingActionButton(
            heroTag: 'resultBtn',
            onPressed: () => _openResultSheet(context, state.result!),
            tooltip: 'Lihat hasil',
            child: const Icon(Icons.assessment_outlined),
          ),
          const SizedBox(width: 12),
        ],
        const _RecordFab(),
      ],
    );
  }
}

void _openResultSheet(BuildContext context, RecitationResult result) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ResultSheet(result: result),
  );
}

class _RecordFab extends StatelessWidget {
  const _RecordFab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationCheckCubit>();
    final state = context.watch<RecitationCheckCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    if (state.status == RecitationStatus.processing) {
      return FloatingActionButton(
        heroTag: 'recFab',
        onPressed: null,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (state.status == RecitationStatus.recording) {
      return FloatingActionButton(
        heroTag: 'recFab',
        onPressed: cubit.stopAndCheck,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        tooltip: 'Berhenti & periksa',
        child: const Icon(Icons.stop),
      );
    }

    final enabled = state.pageAyat.isNotEmpty;
    return FloatingActionButton(
      heroTag: 'recFab',
      onPressed: enabled ? cubit.startRecording : null,
      backgroundColor: enabled ? scheme.primary : null,
      foregroundColor: enabled ? scheme.onPrimary : null,
      tooltip: state.status == RecitationStatus.done
          ? 'Rekam ulang'
          : 'Rekam bacaan',
      child: const Icon(Icons.mic),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final RecitationResult result;
  const _ResultSheet({required this.result});

  static const Color _wrongColor = Color(0xFFE65100);
  static const Color _missingColor = Color(0xFFC62828);
  static const Color _extraColor = Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    final issues = result.diffs
        .where((d) => d.status != WordStatus.correct)
        .toList();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hasil Pemeriksaan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${result.accuracyPercent}%',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(result.accuracy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Kata benar dari total kata pada ayat target'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountChip('Benar', result.correctCount, Colors.green),
                  _CountChip('Salah', result.wrongCount, _wrongColor),
                  _CountChip('Kelewat', result.missingCount, _missingColor),
                  _CountChip('Tambahan', result.extraCount, _extraColor),
                ],
              ),
              const Divider(height: 24),
              const _Legend(),
              const SizedBox(height: 16),
              Text(
                'Detail koreksi',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (issues.isEmpty)
                        const Text('Alhamdulillah, semua kata terbaca benar.')
                      else
                        for (final d in issues) _IssueRow(diff: d),
                      const SizedBox(height: 16),
                      _HeardText(text: result.transcription),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _scoreColor(double acc) {
    if (acc >= 0.9) return Colors.green;
    if (acc >= 0.7) return _wrongColor;
    return _missingColor;
  }
}

/// Satu baris detail koreksi: untuk kata "salah" menampilkan kata mushaf
/// sekaligus apa yang ditangkap sistem dari suara.
class _IssueRow extends StatelessWidget {
  final WordDiff diff;
  const _IssueRow({required this.diff});

  @override
  Widget build(BuildContext context) {
    final ref = diff.referenceWordDisplay ?? diff.referenceWord ?? '';
    final heard = diff.spokenWord ?? '';

    late final String tag;
    late final Color color;
    late final Widget content;
    switch (diff.status) {
      case WordStatus.wrong:
        tag = 'Salah';
        color = _ResultSheet._wrongColor;
        content = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            _ArabicWord(ref, color),
            const Text(
              'terdengar:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            _ArabicWord(heard, _ResultSheet._extraColor),
          ],
        );
      case WordStatus.missing:
        tag = 'Kelewat';
        color = _ResultSheet._missingColor;
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ArabicWord(ref, color, strike: true),
            const SizedBox(width: 8),
            const Text(
              'tidak terbaca',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );
      case WordStatus.extra:
        tag = 'Tambahan';
        color = _ResultSheet._extraColor;
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'terdengar:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(width: 8),
            _ArabicWord(heard, color),
          ],
        );
      case WordStatus.correct:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tag, style: TextStyle(fontSize: 11, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _ArabicWord extends StatelessWidget {
  final String text;
  final Color color;
  final bool strike;
  const _ArabicWord(this.text, this.color, {this.strike = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.isEmpty ? '—' : text,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'QuranHafs',
        fontSize: 20,
        height: 1.5,
        color: color,
        decoration: strike ? TextDecoration.lineThrough : null,
        decorationColor: color,
      ),
    );
  }
}

/// Teks mentah yang ditangkap sistem dari suara (untuk memahami penilaian).
class _HeardText extends StatelessWidget {
  final String text;
  const _HeardText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yang ditangkap sistem',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            text.isEmpty ? '—' : text,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'QuranHafs',
              fontSize: 20,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
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
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      label: Text(
        '$label: $count',
        style: TextStyle(color: color, fontSize: 12),
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
      children: [
        _LegendItem(
          color: Theme.of(context).colorScheme.onSurface,
          label: 'Benar',
        ),
        const _LegendItem(color: Color(0xFFE65100), label: 'Salah baca'),
        const _LegendItem(color: Color(0xFFC62828), label: 'Kelewat (coret)'),
        const _LegendItem(
          color: Colors.blueGrey,
          label: 'Tambahan (garis bawah)',
        ),
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
