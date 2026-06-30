import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';

/// Memuat teks Al-Qur'an dari asset bundel (offline, tanpa biaya).
///
/// Format `assets/quran/quran.json`:
/// `[{ "id":1, "name":"...", "latin":"...", "total_verses":7, "verses":[".."] }]`
class QuranLocalDataSource {
  static const String _assetPath = 'assets/quran/quran.json';

  List<dynamic>? _surahs;

  Future<List<dynamic>> _load() async {
    final cached = _surahs;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    _surahs = decoded;
    return decoded;
  }

  Future<List<SurahInfo>> getSurahList() async {
    final data = await _load();
    return data
        .map((e) => SurahInfo(
              id: e['id'] as int,
              name: e['name'] as String,
              latin: e['latin'] as String,
              totalVerses: e['total_verses'] as int,
            ))
        .toList();
  }

  /// Ayat [from]..[to] (inklusif, 1-based) dari surah [surahId].
  Future<List<Ayah>> getAyatRange({
    required int surahId,
    required int from,
    required int to,
  }) async {
    final data = await _load();
    final surah = data.firstWhere(
      (e) => e['id'] == surahId,
      orElse: () => throw ArgumentError('Surah $surahId tidak ditemukan'),
    );
    final verses = (surah['verses'] as List<dynamic>).cast<String>();

    final lo = from < 1 ? 1 : from;
    final hi = to > verses.length ? verses.length : to;
    final result = <Ayah>[];
    for (var n = lo; n <= hi; n++) {
      result.add(Ayah(surahId: surahId, number: n, text: verses[n - 1]));
    }
    return result;
  }
}
