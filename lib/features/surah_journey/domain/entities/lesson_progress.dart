/// Progres seorang pengguna pada SATU BAGIAN sebuah surah.
class SectionProgress {
  /// Pernah lulus ujian bagian ini.
  final bool passed;

  /// Jumlah benar terbaik yang pernah dicapai.
  final int bestCorrect;

  const SectionProgress({this.passed = false, this.bestCorrect = 0});

  static const empty = SectionProgress();

  Map<String, dynamic> toMap() => {'passed': passed, 'best': bestCorrect};

  factory SectionProgress.fromMap(Map<String, dynamic> map) => SectionProgress(
    passed: map['passed'] == true,
    bestCorrect: (map['best'] as num?)?.toInt() ?? 0,
  );
}

/// Progres seorang pengguna pada SATU surah Petualangan Surah.
class SurahProgress {
  /// Progres per bagian, kunci = [LessonSection.id].
  final Map<String, SectionProgress> sections;

  /// Pernah lulus UJIAN AKHIR surah → level selesai (centang hijau di peta).
  final bool examPassed;

  /// Nilai ujian akhir terbaik (0..100). 0 = belum pernah ujian.
  final int examBestScore;

  const SurahProgress({
    this.sections = const {},
    this.examPassed = false,
    this.examBestScore = 0,
  });

  static const empty = SurahProgress();

  bool get completed => examPassed;

  SectionProgress of(String sectionId) =>
      sections[sectionId] ?? SectionProgress.empty;

  /// Semua bagian pada [sectionIds] sudah lulus (syarat buka ujian akhir).
  bool allSectionsPassed(Iterable<String> sectionIds) =>
      sectionIds.every((id) => of(id).passed);

  SurahProgress withSection(String sectionId, SectionProgress progress) =>
      SurahProgress(
        sections: {...sections, sectionId: progress},
        examPassed: examPassed,
        examBestScore: examBestScore,
      );

  SurahProgress withExam({required bool passed, required int score}) =>
      SurahProgress(
        sections: sections,
        examPassed: examPassed || passed,
        examBestScore: score > examBestScore ? score : examBestScore,
      );

  Map<String, dynamic> toMap() => {
    'sections': {for (final e in sections.entries) e.key: e.value.toMap()},
    'exam': {'passed': examPassed, 'best_score': examBestScore},
    'completed': completed,
  };

  factory SurahProgress.fromMap(Map<String, dynamic> map) {
    final rawSections = map['sections'];
    final sections = <String, SectionProgress>{};
    if (rawSections is Map<String, dynamic>) {
      rawSections.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          sections[key] = SectionProgress.fromMap(value);
        }
      });
    }
    final exam = map['exam'];
    return SurahProgress(
      sections: sections,
      examPassed: exam is Map<String, dynamic> && exam['passed'] == true,
      examBestScore: exam is Map<String, dynamic>
          ? ((exam['best_score'] as num?)?.toInt() ?? 0)
          : 0,
    );
  }
}

/// Progres seluruh peta journey milik satu pengguna.
class JourneyProgress {
  /// Progres per nomor surah.
  final Map<int, SurahProgress> surahs;

  /// Total XP yang terkumpul.
  final int xp;

  const JourneyProgress({this.surahs = const {}, this.xp = 0});

  SurahProgress of(int surahId) => surahs[surahId] ?? SurahProgress.empty;
}
