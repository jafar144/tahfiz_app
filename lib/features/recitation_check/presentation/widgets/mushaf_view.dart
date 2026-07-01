import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';

/// Satu halaman mushaf hasil pengelompokan [Ayah] berdasarkan nomor halaman.
class MushafPage {
  final int page;
  final List<Ayah> ayat;
  const MushafPage(this.page, this.ayat);
}

/// Kelompokkan ayat (urut mushaf) menjadi halaman-halaman terpisah.
List<MushafPage> groupAyatByPage(List<Ayah> ayat) {
  final out = <MushafPage>[];
  int? current;
  var buf = <Ayah>[];
  for (final a in ayat) {
    if (a.page != current) {
      if (buf.isNotEmpty) out.add(MushafPage(current!, buf));
      buf = <Ayah>[];
      current = a.page;
    }
    buf.add(a);
  }
  if (buf.isNotEmpty && current != null) out.add(MushafPage(current, buf));
  return out;
}

/// Petakan tiap ayat target -> daftar [WordDiff] miliknya (urut), dengan
/// kunci `'<surahId>:<number>'`. Dihitung sekali lalu dipakai lintas halaman.
Map<String, List<WordDiff>> buildTargetColoring(
  List<Ayah> targetAyat,
  RecitationResult result,
) {
  final map = <String, List<WordDiff>>{};
  final diffs = result.diffs;
  var cursor = 0;
  for (final a in targetAyat) {
    final tokenCount = ArabicNormalizer.tokenizeWithOriginal(a.text).length;
    final slice = <WordDiff>[];
    var placed = 0;
    while (cursor < diffs.length && placed < tokenCount) {
      final d = diffs[cursor];
      slice.add(d);
      cursor++;
      if (d.status != WordStatus.extra) placed++;
    }
    map['${a.surahId}:${a.number}'] = slice;
  }
  if (cursor < diffs.length && targetAyat.isNotEmpty) {
    final last = targetAyat.last;
    map['${last.surahId}:${last.number}']!.addAll(diffs.sublist(cursor));
  }
  return map;
}

/// Menampilkan SATU halaman mushaf Madinah (KFGQPC Uthmanic Hafs) menyerupai
/// aplikasi Al-Qur'an: teks rata kiri-kanan (justify), edge-to-edge, dan
/// ukuran font otomatis diskalakan agar seluruh halaman muat dalam satu layar
/// tanpa scroll.
///
/// Header surah + basmalah hanya tampil di halaman tempat surah dimulai. Ayat
/// pada rentang target diberi warna per kata via [coloredWords].
class MushafView extends StatelessWidget {
  final List<Ayah> ayat; // ayat pada satu halaman
  final int targetSurahId;
  final int fromAyah;
  final int toAyah;
  final Map<String, List<WordDiff>>? coloredWords;

  /// Ruang bawah yang disisakan agar tak tertutup tombol Rekam yang mengambang.
  final double bottomReserve;

  const MushafView({
    super.key,
    required this.ayat,
    required this.targetSurahId,
    required this.fromAyah,
    required this.toAyah,
    this.coloredWords,
    this.bottomReserve = 92,
  });

  static const String _fontFamily = 'QuranHafs';
  static const double _lineHeight = 1.7;
  static const String _basmalah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

  static const Color _wrongColor = Color(0xFFE65100);
  static const Color _missingColor = Color(0xFFC62828);
  static const Color _extraColor = Colors.blueGrey;

  bool _isTarget(Ayah a) =>
      a.surahId == targetSurahId && a.number >= fromAyah && a.number <= toAyah;

  TextStyle _root(double size, Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        height: _lineHeight,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    if (ayat.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final blocks = _buildBlocks(scheme);

    return LayoutBuilder(
      builder: (context, c) {
        const hPad = 6.0;
        final width = (c.maxWidth - hPad * 2).clamp(0.0, double.infinity);
        final availH = (c.maxHeight - bottomReserve).clamp(0.0, double.infinity);

        final size = _fitFontSize(blocks, width, availH, scheme.onSurface, textScaler);
        final content = SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final b in blocks) _renderBlock(b, size, scheme),
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
          child: SizedBox(
            height: availH,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        );
      },
    );
  }

  // ---- Membangun blok (tak bergantung ukuran font) ----

  List<_Block> _buildBlocks(ColorScheme scheme) {
    final blocks = <_Block>[];
    var spans = <InlineSpan>[];

    void flush() {
      if (spans.isEmpty) return;
      blocks.add(_TextBlock(spans));
      spans = <InlineSpan>[];
    }

    for (final a in ayat) {
      if (a.isSurahStart) {
        flush();
        blocks.add(_HeaderBlock(a.surahName));
        if (a.surahId != 1 && a.surahId != 9) blocks.add(const _BasmalahBlock());
      }
      final slice = coloredWords?['${a.surahId}:${a.number}'];
      if (_isTarget(a) && slice != null) {
        _appendColoredAyah(a, slice, spans, scheme);
      } else {
        spans.add(TextSpan(text: '${a.text} '));
      }
    }
    flush();
    return blocks;
  }

  void _appendColoredAyah(
    Ayah a,
    List<WordDiff> slice,
    List<InlineSpan> out,
    ColorScheme scheme,
  ) {
    for (final d in slice) {
      if (d.status == WordStatus.extra) {
        final w = d.spokenWord ?? '';
        if (w.isEmpty) continue;
        out.add(TextSpan(
          text: '$w ',
          style: const TextStyle(
            color: _extraColor,
            decoration: TextDecoration.underline,
            decorationColor: _extraColor,
          ),
        ));
        continue;
      }
      final text = d.referenceWordDisplay ?? d.referenceWord ?? '';
      out.add(TextSpan(text: '$text ', style: _styleFor(d.status)));
    }
    out.add(TextSpan(
      text: '${_ayahNumberGlyph(a.text)} ',
      style: TextStyle(color: scheme.primary),
    ));
  }

  TextStyle? _styleFor(WordStatus status) {
    switch (status) {
      case WordStatus.correct:
        return null; // warna default (mushaf normal)
      case WordStatus.wrong:
        return const TextStyle(
          color: _wrongColor,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dashed,
          decorationColor: _wrongColor,
        );
      case WordStatus.missing:
        return const TextStyle(
          color: _missingColor,
          decoration: TextDecoration.lineThrough,
          decorationColor: _missingColor,
        );
      case WordStatus.extra:
        return null;
    }
  }

  // ---- Fit ukuran font agar muat tinggi layar ----

  double _fitFontSize(
    List<_Block> blocks,
    double width,
    double availH,
    Color color,
    TextScaler textScaler,
  ) {
    if (width <= 0 || availH <= 0) return 22;
    var lo = 14.0;
    var hi = 38.0;
    for (var i = 0; i < 9; i++) {
      final mid = (lo + hi) / 2;
      if (_measureHeight(blocks, mid, width, color, textScaler) <= availH) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  double _measureHeight(
    List<_Block> blocks,
    double size,
    double width,
    Color color,
    TextScaler textScaler,
  ) {
    final root = _root(size, color);
    var h = 0.0;
    for (final b in blocks) {
      if (b is _HeaderBlock) {
        h += size * 1.4 + 36; // kotak header (perkiraan konservatif)
      } else if (b is _BasmalahBlock) {
        h += _measureSpan(TextSpan(text: _basmalah, style: root), width, textScaler);
      } else if (b is _TextBlock) {
        h += _measureSpan(TextSpan(children: b.spans, style: root), width, textScaler);
      }
      h += 8; // jarak antar blok
    }
    return h;
  }

  double _measureSpan(InlineSpan span, double width, TextScaler textScaler) {
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      textScaler: textScaler,
    )..layout(maxWidth: width);
    final h = tp.height;
    tp.dispose();
    return h;
  }

  // ---- Render blok pada ukuran font terpilih ----

  Widget _renderBlock(_Block b, double size, ColorScheme scheme) {
    if (b is _HeaderBlock) {
      return _SurahHeader(name: b.name, fontFamily: _fontFamily);
    }
    if (b is _BasmalahBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          _basmalah,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: _root(size, scheme.onSurface),
        ),
      );
    }
    final tb = b as _TextBlock;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: tb.spans),
        textAlign: TextAlign.justify,
        style: _root(size, scheme.onSurface),
      ),
    );
  }

  static String _ayahNumberGlyph(String ayaText) {
    final parts = ayaText.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.last;
  }
}

sealed class _Block {
  const _Block();
}

class _HeaderBlock extends _Block {
  final String name;
  const _HeaderBlock(this.name);
}

class _BasmalahBlock extends _Block {
  const _BasmalahBlock();
}

class _TextBlock extends _Block {
  final List<InlineSpan> spans;
  const _TextBlock(this.spans);
}

class _SurahHeader extends StatelessWidget {
  final String name;
  final String fontFamily;
  const _SurahHeader({required this.name, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            'سُورَةُ $name',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 20,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
