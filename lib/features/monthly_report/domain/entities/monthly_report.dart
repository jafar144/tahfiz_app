class MonthlyReport {
  final String id;
  final String asatidzId;
  final String asatidzName;
  final String santriId;
  final String santriName;
  final int bulan;
  final int tahun;
  final String hafalanTerakhir;
  final int nilaiPerkembangan;
  final int nilaiAkhlaq;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyReport({
    required this.id,
    required this.asatidzId,
    required this.asatidzName,
    required this.santriId,
    required this.santriName,
    required this.bulan,
    required this.tahun,
    required this.hafalanTerakhir,
    required this.nilaiPerkembangan,
    required this.nilaiAkhlaq,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  static String getNilaiLabel(int nilai) {
    switch (nilai) {
      case 5:
        return 'Sangat Baik';
      case 4:
        return 'Baik';
      case 3:
        return 'Cukup';
      case 2:
        return 'Kurang';
      case 1:
        return 'Sangat Kurang';
      default:
        return '-';
    }
  }

  static String getNamaBulan(int bulan) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return (bulan >= 1 && bulan <= 12) ? names[bulan] : '-';
  }
}
