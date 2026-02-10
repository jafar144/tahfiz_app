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
  final int ayatAwal;
  final int ayatAkhir;
  final String kualitasHafalan;
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
    required this.ayatAwal,
    required this.ayatAkhir,
    required this.kualitasHafalan,
    this.catatan = '',
    required this.createdAt,
  });
}
