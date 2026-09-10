/// Kurikulum lembaga yang dapat dipakai oleh sistem progres, pembelajaran,
/// maupun adapter fitur seperti kuis.
class InstitutionCurriculum {
  final List<String> classNames;
  final List<String> classTypes;
  final Map<String, MemorizationScope> memorizationByClass;

  /// Daftar capaian kelulusan lintas kelas dalam urutan kurikulum lembaga.
  final List<GraduationMilestone> graduationMilestones;

  /// Rentang capaian yang boleh dipilih untuk setiap kelas.
  final Map<String, GraduationMilestoneRange> graduationMilestoneRanges;

  /// Alias nama kelas historis yang masih mungkin tersimpan di Firestore.
  final Map<String, String> classAliases;

  /// Jenjang kelas fiqih yang dapat dipilih pada profil santri.
  final List<String> fiqihClassNames;

  /// Kelas tahfiz pertama yang boleh memiliki kelas fiqih. Semua kelas pada
  /// urutan [classNames] mulai dari kelas ini ikut dianggap memenuhi syarat.
  final String? firstFiqihEligibleClass;

  /// Pemetaan kelas ke satu tingkat cakupan alternatif di bawahnya.
  final Map<String, String> previousChallengeClass;

  const InstitutionCurriculum({
    required this.classNames,
    required this.classTypes,
    required this.memorizationByClass,
    this.graduationMilestones = const [],
    this.graduationMilestoneRanges = const {},
    this.classAliases = const {},
    this.fiqihClassNames = const [],
    this.firstFiqihEligibleClass,
    this.previousChallengeClass = const {},
  });

  String? normalizeClassName(String? className) {
    final value = className?.trim();
    if (value == null || value.isEmpty) return null;
    if (classNames.contains(value)) return value;
    final canonical = classAliases[value];
    return canonical != null && classNames.contains(canonical)
        ? canonical
        : null;
  }

  MemorizationScope? scopeFor(String? className) {
    final canonical = normalizeClassName(className);
    return canonical == null ? null : memorizationByClass[canonical];
  }

  String? classBelow(String? className) {
    final canonical = normalizeClassName(className);
    return canonical == null ? null : previousChallengeClass[canonical];
  }

  List<GraduationMilestone> graduationMilestonesFor(String? className) {
    final canonical = normalizeClassName(className);
    final range = canonical == null
        ? null
        : graduationMilestoneRanges[canonical];
    if (range == null || graduationMilestones.isEmpty) return const [];
    return graduationMilestones
        .where((item) => range.contains(item.number))
        .toList(growable: false);
  }

  GraduationPromotion? graduationPromotionFor(
    String? className,
    GraduationMilestone milestone,
  ) {
    final canonical = normalizeClassName(className);
    final range = canonical == null
        ? null
        : graduationMilestoneRanges[canonical];
    if (canonical == null || range == null || milestone.number != range.end) {
      return null;
    }
    final classIndex = classNames.indexOf(canonical);
    if (classIndex < 0 || classIndex >= classNames.length - 1) return null;
    return GraduationPromotion(
      fromClass: canonical,
      toClass: classNames[classIndex + 1],
      milestone: milestone,
    );
  }

  List<String> get classesWithMemorization => [
    for (final className in classNames)
      if (memorizationByClass.containsKey(className)) className,
  ];

  bool isFiqihEligible(String? className) {
    if (className == null || firstFiqihEligibleClass == null) return false;
    final selectedIndex = classNames.indexOf(
      normalizeClassName(className) ?? '',
    );
    final firstEligibleIndex = classNames.indexOf(firstFiqihEligibleClass!);
    return firstEligibleIndex >= 0 && selectedIndex >= firstEligibleIndex;
  }

  String? normalizeFiqihClass(String? className, String? fiqihClass) {
    final value = fiqihClass?.trim();
    if (!isFiqihEligible(className) || !fiqihClassNames.contains(value)) {
      return null;
    }
    return value;
  }
}

class GraduationMilestone {
  final int number;
  final String label;

  const GraduationMilestone(this.number, this.label);

  String get displayLabel => '$number. $label';
}

class GraduationMilestoneRange {
  final int start;
  final int end;

  const GraduationMilestoneRange(this.start, this.end)
    : assert(start > 0),
      assert(end >= start);

  bool contains(int number) => number >= start && number <= end;
}

class GraduationPromotion {
  final String fromClass;
  final String toClass;
  final GraduationMilestone milestone;

  const GraduationPromotion({
    required this.fromClass,
    required this.toClass,
    required this.milestone,
  });

  Map<String, dynamic> toJson() => {
    'fromClass': fromClass,
    'toClass': toClass,
    'milestoneNumber': milestone.number,
  };
}

/// Cakupan hafalan kumulatif sebuah kelas.
class MemorizationScope {
  final List<int> juz;
  final Set<int> extraSurahs;

  const MemorizationScope({required this.juz, this.extraSurahs = const {}});
}
