/// Kurikulum lembaga yang dapat dipakai oleh sistem progres, pembelajaran,
/// maupun adapter fitur seperti kuis.
class InstitutionCurriculum {
  final List<String> classNames;
  final List<String> classTypes;
  final Map<String, MemorizationScope> memorizationByClass;

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
    this.fiqihClassNames = const [],
    this.firstFiqihEligibleClass,
    this.previousChallengeClass = const {},
  });

  MemorizationScope? scopeFor(String? className) =>
      className == null ? null : memorizationByClass[className.trim()];

  String? classBelow(String? className) =>
      className == null ? null : previousChallengeClass[className.trim()];

  List<String> get classesWithMemorization => [
    for (final className in classNames)
      if (memorizationByClass.containsKey(className)) className,
  ];

  bool isFiqihEligible(String? className) {
    if (className == null || firstFiqihEligibleClass == null) return false;
    final selectedIndex = classNames.indexOf(className.trim());
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

/// Cakupan hafalan kumulatif sebuah kelas.
class MemorizationScope {
  final List<int> juz;
  final Set<int> extraSurahs;

  const MemorizationScope({required this.juz, this.extraSurahs = const {}});
}
