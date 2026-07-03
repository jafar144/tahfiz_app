import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';

/// Penyimpanan setelan kuis di lokal (file JSON pada direktori dukungan app),
/// agar pilihan mode/juz/rentang target diingat antar sesi. Sengaja memakai
/// `path_provider` (sudah ada) alih-alih menambah dependensi baru.
class QuizSettingsStore {
  static const String _fileName = 'quiz_settings.json';

  File? _cachedFile;

  Future<File> _file() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final dir = await getApplicationSupportDirectory();
    final f = File('${dir.path}/$_fileName');
    _cachedFile = f;
    return f;
  }

  /// Muat setelan tersimpan; kembalikan default bila belum ada / gagal baca.
  Future<QuizSettings> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const QuizSettings();
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return const QuizSettings();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return QuizSettings.fromJson(json);
    } catch (_) {
      return const QuizSettings();
    }
  }

  /// Simpan setelan (best-effort; kegagalan tak mengganggu alur main).
  Future<void> save(QuizSettings settings) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(settings.toJson()), flush: true);
    } catch (_) {
      // Diabaikan.
    }
  }
}
