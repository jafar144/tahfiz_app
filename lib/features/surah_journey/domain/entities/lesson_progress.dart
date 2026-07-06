/// Progres seorang pengguna pada SATU surah Petualangan Surah.
class SurahProgress {
  /// Pernah membuka & menyelesaikan halaman belajar surah ini.
  final bool learned;

  /// Nilai ujian terbaik (0..100). 0 = belum pernah ujian.
  final int bestScore;

  /// Level dianggap SELESAI (pernah mencapai ambang lulus) → centang hijau.
  final bool completed;

  const SurahProgress({
    this.learned = false,
    this.bestScore = 0,
    this.completed = false,
  });

  static const empty = SurahProgress();

  SurahProgress copyWith({bool? learned, int? bestScore, bool? completed}) {
    return SurahProgress(
      learned: learned ?? this.learned,
      bestScore: bestScore ?? this.bestScore,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() => {
    'learned': learned,
    'best_score': bestScore,
    'completed': completed,
  };

  factory SurahProgress.fromMap(Map<String, dynamic> map) => SurahProgress(
    learned: map['learned'] == true,
    bestScore: (map['best_score'] as num?)?.toInt() ?? 0,
    completed: map['completed'] == true,
  );
}

/// Progres seluruh peta journey milik satu pengguna (per surah).
class JourneyProgress {
  /// Progres per nomor surah.
  final Map<int, SurahProgress> surahs;

  const JourneyProgress({this.surahs = const {}});

  SurahProgress of(int surahId) => surahs[surahId] ?? SurahProgress.empty;

  JourneyProgress withSurah(int surahId, SurahProgress progress) {
    return JourneyProgress(surahs: {...surahs, surahId: progress});
  }
}
