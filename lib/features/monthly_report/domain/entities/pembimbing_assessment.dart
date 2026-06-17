/// Ringkasan status penilaian bulanan untuk satu pembimbing (asatidz).
///
/// Dipakai di sisi admin untuk memantau pembimbing mana yang belum
/// menyelesaikan penilaian terhadap santri binaannya pada bulan berjalan.
class PembimbingAssessment {
  final String asatidzId;
  final String asatidzName;

  /// Jenis kelamin pembimbing: 'L' atau 'P'. Dipakai untuk filter tab
  /// (Putra/Putri) dan penentuan gelar pada pesan pengingat.
  final String gender;
  final int totalSantri;

  /// Santri binaan yang belum diberi penilaian pada bulan ini.
  final List<UnassessedSantri> unassessedSantri;

  const PembimbingAssessment({
    required this.asatidzId,
    required this.asatidzName,
    required this.gender,
    required this.totalSantri,
    required this.unassessedSantri,
  });

  int get unassessedCount => unassessedSantri.length;

  bool get isComplete => unassessedSantri.isEmpty && totalSantri > 0;

  /// Persentase santri yang belum dinilai (0..100).
  double get unassessedPercent =>
      totalSantri == 0 ? 0 : (unassessedCount / totalSantri) * 100;
}

/// Santri yang belum dinilai, hanya menyimpan data yang diperlukan
/// untuk ditampilkan & disusun ke dalam pesan pengingat.
class UnassessedSantri {
  final String id;
  final String name;
  final String nis;

  const UnassessedSantri({
    required this.id,
    required this.name,
    required this.nis,
  });
}
