abstract class AdminHomeRemoteDatasource {
  Future<int> getTotalSantriPutra();
  Future<int> getTotalSantriPutri();
  Future<int> getTotalAsatidzPutra();
  Future<int> getTotalAsatidzPutri();

  /// Jumlah santri aktif untuk kombinasi jenis kelamin dan sesi kelas.
  Future<int> getTotalSantriByGenderAndSession({
    required String gender,
    required String session,
  });

  /// Jumlah santri yang masuk (berdasarkan `tanggal_masuk`) dalam 30 hari
  /// terakhir untuk [gender] ('L'/'P').
  Future<int> getSantriMasuk30d(String gender);

  /// Jumlah santri yang keluar (berdasarkan `tanggal_keluar`) dalam 30 hari
  /// terakhir untuk [gender] ('L'/'P').
  Future<int> getSantriKeluar30d(String gender);
}
