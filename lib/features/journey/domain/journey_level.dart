import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';

/// Status sebuah tingkat dalam perjalanan tahfiz santri.
enum JourneyStatus { completed, active, locked }

/// Satu tingkat (kelas) dalam perjalanan tahfiz.
class JourneyLevel {
  /// Index 0-based sesuai urutan [AppConstants.santriClasses].
  final int index;
  final String name;
  final String description;
  final IconData icon;
  final JourneyStatus status;

  const JourneyLevel({
    required this.index,
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
  });

  /// Nomor tingkat 1-based untuk ditampilkan.
  int get number => index + 1;

  bool get isCompleted => status == JourneyStatus.completed;
  bool get isActive => status == JourneyStatus.active;
  bool get isLocked => status == JourneyStatus.locked;
}

/// Ringkasan perjalanan: seluruh tingkat + posisi kelas santri saat ini.
class JourneyInfo {
  final List<JourneyLevel> levels;

  /// Index kelas santri saat ini. Bernilai -1 bila kelas tidak dikenali.
  final int currentIndex;

  const JourneyInfo({required this.levels, required this.currentIndex});

  int get total => levels.length;
  bool get hasCurrent => currentIndex >= 0 && currentIndex < levels.length;
  JourneyLevel? get current => hasCurrent ? levels[currentIndex] : null;
}

/// Membangun [JourneyInfo] dari kelas santri saat ini.
///
/// Urutan tingkat mengikuti [AppConstants.santriClasses]. Semua tingkat sebelum
/// kelas santri dianggap selesai, kelas saat ini aktif, sisanya terkunci.
class JourneyBuilder {
  const JourneyBuilder._();

  // Deskripsi singkat tiap tingkat (mudah disesuaikan ustadz bila perlu).
  static const List<String> _descriptions = [
    'Memperbaiki bacaan dasar & makhorijul huruf.',
    'Memantapkan tajwid & kelancaran membaca.',
    'Tahap menengah, penguatan bacaan & hafalan.',
    'Persiapan awal menuju program takhossus.',
    'Pemantapan sebelum masuk takhossus.',
    'Memulai pendalaman hafalan Al-Qur\'an.',
    'Melanjutkan penambahan & muroja\'ah hafalan.',
    'Memperkuat hafalan dengan muroja\'ah rutin.',
    'Hafalan semakin matang mendekati target.',
    'Tahap lanjut menuju penyempurnaan hafalan.',
    'Penyempurnaan hafalan & persiapan khatam 30 juz.',
  ];

  static const List<IconData> _icons = [
    Icons.spa_rounded,
    Icons.local_florist_rounded,
    Icons.auto_stories_rounded,
    Icons.menu_book_rounded,
    Icons.import_contacts_rounded,
    Icons.star_outline_rounded,
    Icons.star_half_rounded,
    Icons.star_rounded,
    Icons.brightness_3_rounded,
    Icons.auto_awesome_rounded,
    Icons.workspace_premium_rounded,
  ];

  static JourneyInfo build(String? currentKelas) {
    final classes = AppConstants.santriClasses;
    final currentIndex =
        currentKelas == null ? -1 : classes.indexOf(currentKelas.trim());

    final levels = <JourneyLevel>[];
    for (var i = 0; i < classes.length; i++) {
      final JourneyStatus status;
      if (currentIndex < 0) {
        status = JourneyStatus.locked;
      } else if (i < currentIndex) {
        status = JourneyStatus.completed;
      } else if (i == currentIndex) {
        status = JourneyStatus.active;
      } else {
        status = JourneyStatus.locked;
      }

      levels.add(JourneyLevel(
        index: i,
        name: classes[i],
        description: i < _descriptions.length ? _descriptions[i] : '',
        icon: i < _icons.length ? _icons[i] : Icons.menu_book_rounded,
        status: status,
      ));
    }

    return JourneyInfo(levels: levels, currentIndex: currentIndex);
  }
}
