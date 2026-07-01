import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';

/// Memuat teks Al-Qur'an mushaf Madinah (KFGQPC Uthmanic Hafs v18) dari asset
/// bundel — offline, lengkap dengan nomor halaman untuk tampilan per-halaman.
///
/// Format `assets/quran/hafs_v18.json` (array 6236 ayat):
/// `{ "sora":1, "aya_no":1, "page":1, "aya_text":"...", "sora_name_ar":"...",
///    "sora_name_en":"..." }`
class QuranLocalDataSource {
  static const String _assetPath = 'assets/quran/hafs_v18.json';

  List<_Row>? _rows;
  List<SurahInfo>? _surahs;

  Future<List<_Row>> _load() async {
    final cached = _rows;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    final rows = decoded
        .map((e) => _Row(
              surah: e['sora'] as int,
              ayah: e['aya_no'] as int,
              page: e['page'] as int,
              text: e['aya_text'] as String,
              surahNameAr: e['sora_name_ar'] as String,
              surahNameEn: e['sora_name_en'] as String,
            ))
        .toList(growable: false);
    _rows = rows;
    return rows;
  }

  Ayah _toAyah(_Row r) => Ayah(
        surahId: r.surah,
        number: r.ayah,
        text: r.text,
        page: r.page,
        surahName: r.surahNameAr,
      );

  Future<List<SurahInfo>> getSurahList() async {
    final cached = _surahs;
    if (cached != null) return cached;
    final rows = await _load();
    final byId = <int, _Row>{};
    final totals = <int, int>{};
    for (final r in rows) {
      byId.putIfAbsent(r.surah, () => r);
      final t = totals[r.surah] ?? 0;
      if (r.ayah > t) totals[r.surah] = r.ayah;
    }
    final surahs = byId.keys.toList()..sort();
    final result = surahs
        .map((id) => SurahInfo(
              id: id,
              name: byId[id]!.surahNameAr,
              latin: byId[id]!.surahNameEn,
              totalVerses: totals[id] ?? 0,
            ))
        .toList();
    _surahs = result;
    return result;
  }

  /// Ayat [from]..[to] (inklusif, 1-based) dari surah [surahId] — sebagai
  /// target pemeriksaan bacaan.
  Future<List<Ayah>> getAyatRange({
    required int surahId,
    required int from,
    required int to,
  }) async {
    final rows = await _load();
    final lo = from < 1 ? 1 : from;
    final hi = to < lo ? lo : to;
    return rows
        .where((r) => r.surah == surahId && r.ayah >= lo && r.ayah <= hi)
        .map(_toAyah)
        .toList();
  }

  /// Semua ayat dari surah [fromSurah]..[toSurah] (inklusif) urut sesuai mushaf.
  /// Dipakai mis. untuk menyusun pool soal kuis satu juz.
  Future<List<Ayah>> getAyatForSurahRange({
    required int fromSurah,
    required int toSurah,
  }) async {
    final rows = await _load();
    return rows
        .where((r) => r.surah >= fromSurah && r.surah <= toSurah)
        .map(_toAyah)
        .toList();
  }

  /// Semua ayat pada halaman mushaf yang memuat rentang target
  /// [surahId]:[from]..[to] — termasuk surah tetangga di halaman yang sama,
  /// urut sesuai mushaf. Dipakai untuk menampilkan halaman penuh.
  Future<List<Ayah>> getPageAyat({
    required int surahId,
    required int from,
    required int to,
  }) async {
    final rows = await _load();
    final lo = from < 1 ? 1 : from;
    final hi = to < lo ? lo : to;
    final pages = <int>{};
    for (final r in rows) {
      if (r.surah == surahId && r.ayah >= lo && r.ayah <= hi) {
        pages.add(r.page);
      }
    }
    if (pages.isEmpty) return const [];
    // rows sudah urut global (mushaf); cukup filter berdasarkan halaman.
    return rows.where((r) => pages.contains(r.page)).map(_toAyah).toList();
  }
}

class _Row {
  final int surah;
  final int ayah;
  final int page;
  final String text;
  final String surahNameAr;
  final String surahNameEn;

  const _Row({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.text,
    required this.surahNameAr,
    required this.surahNameEn,
  });
}
