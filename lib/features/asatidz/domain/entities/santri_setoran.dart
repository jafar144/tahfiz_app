class SantriSetoran {
  final String id;
  final String santriId;
  final String santriName;
  final String halaqahId;
  final String halaqahName;
  final String asatidzId;
  final String asatidzName;
  final DateTime date;
  final String surah;
  final String catatan;
  final DateTime createdAt;

  SantriSetoran({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.halaqahId,
    required this.halaqahName,
    required this.asatidzId,
    required this.asatidzName,
    required this.date,
    required this.surah,
    this.catatan = '',
    required this.createdAt,
  });
}
