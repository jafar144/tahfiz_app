class AdminHomeData {
  final String adminName;
  final int totalSantriPutra;
  final int totalSantriPutri;
  final int totalAsatidzPutra;
  final int totalAsatidzPutri;

  /// Rincian santri aktif pada sesi utama tiap kelompok.
  final int santriPutraSore;
  final int santriPutraMalam;
  final int santriPutriPagi;
  final int santriPutriSore;

  /// Mutasi santri 30 hari terakhir (masuk = tanggal_masuk, keluar = tanggal_keluar).
  final int masukPutra;
  final int masukPutri;
  final int keluarPutra;
  final int keluarPutri;

  AdminHomeData({
    required this.adminName,
    required this.totalSantriPutra,
    required this.totalSantriPutri,
    required this.totalAsatidzPutra,
    required this.totalAsatidzPutri,
    this.santriPutraSore = 0,
    this.santriPutraMalam = 0,
    this.santriPutriPagi = 0,
    this.santriPutriSore = 0,
    this.masukPutra = 0,
    this.masukPutri = 0,
    this.keluarPutra = 0,
    this.keluarPutri = 0,
  });
}
