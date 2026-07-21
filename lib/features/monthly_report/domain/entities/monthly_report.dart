class MonthlyReport {
  final String id;
  final String asatidzId;
  final String asatidzName;

  /// Gender pengajar ('L' / 'P'), dipakai untuk gelar Ustadz/Ustadzah.
  /// Bisa kosong bila tidak diketahui.
  final String asatidzGender;
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
    this.asatidzGender = '',
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

  /// Data dummy untuk keperluan skeleton loading.
  factory MonthlyReport.dummy() => MonthlyReport(
    id: 'dummy',
    asatidzId: '',
    asatidzName: 'Ustadz Fulan',
    santriId: '',
    santriName: 'Santri',
    bulan: 1,
    tahun: 2024,
    hafalanTerakhir: 'Al-Baqarah ayat 1-20',
    nilaiPerkembangan: 4,
    nilaiAkhlaq: 4,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  /// Gelar pengajar berdasarkan gender: 'Ustadz' / 'Ustadzah' / '' (tak diketahui).
  String get asatidzTitle => switch (asatidzGender) {
    'L' => 'Ustadz',
    'P' => 'Ustadzah',
    _ => '',
  };

  /// Nama pengajar lengkap dengan gelar, mis. "Ustadz Ja'far Assegaf".
  String get asatidzDisplayName =>
      asatidzTitle.isEmpty ? asatidzName : '$asatidzTitle $asatidzName';

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
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return (bulan >= 1 && bulan <= 12) ? names[bulan] : '-';
  }
}
