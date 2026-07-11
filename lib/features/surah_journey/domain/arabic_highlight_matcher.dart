/// Rentang indeks teks asli untuk satu kosa kata Arab yang ditemukan.
class ArabicHighlightRange {
  final int start;
  final int end;

  const ArabicHighlightRange({required this.start, required this.end});
}

/// Mencari kosa kata pada teks mushaf tanpa terpengaruh perbedaan tanda baca
/// Qur'an, harakat, tatwil, atau bentuk alif yang setara.
///
/// Teks yang disorot tetap memakai rentang teks asli agar rasm dan harakat
/// mushaf tidak berubah di layar.
class ArabicHighlightMatcher {
  ArabicHighlightMatcher._();

  static ArabicHighlightRange? find({
    required String text,
    required String highlight,
  }) {
    final target = _normalize(highlight);
    if (target.isEmpty) return null;

    final source = _normalizeWithOffsets(text);
    final sourceText = source.map((char) => char.value).join();
    final index = sourceText.indexOf(target);
    if (index < 0) return null;

    final first = source[index];
    final last = source[index + target.length - 1];
    var end = last.end;
    while (end < text.length && _isIgnored(text.codeUnitAt(end))) {
      end++;
    }
    return ArabicHighlightRange(start: first.start, end: end);
  }

  static String _normalize(String value) =>
      _normalizeWithOffsets(value).map((char) => char.value).join();

  static List<_NormalizedChar> _normalizeWithOffsets(String value) {
    final chars = <_NormalizedChar>[];
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (_isIgnored(code)) continue;
      chars.add(_NormalizedChar(_baseForm(code), i, i + 1));
    }
    return chars;
  }

  static bool _isIgnored(int code) =>
      code == 0x0640 ||
      (code >= 0x0610 && code <= 0x061A) ||
      (code >= 0x064B && code <= 0x065F) ||
      code == 0x0670 ||
      (code >= 0x06D6 && code <= 0x06ED);

  static String _baseForm(int code) {
    switch (code) {
      case 0x0622:
      case 0x0623:
      case 0x0625:
      case 0x0671:
        return '\u0627';
      case 0x0649:
        return '\u064A';
      default:
        return String.fromCharCode(code);
    }
  }
}

class _NormalizedChar {
  final String value;
  final int start;
  final int end;

  const _NormalizedChar(this.value, this.start, this.end);
}
