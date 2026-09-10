/// Nilai periode yang mungkin tersimpan pada dokumen laporan lama.
///
/// Data baru selalu memakai [int], sedangkan sebagian data hasil impor lama
/// menyimpan bulan dan tahun sebagai [String].
List<Object> monthlyReportPeriodStorageValues(int value) => [
  value,
  value.toString(),
];

int? parseMonthlyReportPeriod(Object? raw) {
  final value = switch (raw) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()),
    _ => null,
  };

  return value != null && value > 0 ? value : null;
}

/// Menggabungkan hasil beberapa query periode dan menghapus ID yang duplikat.
Set<String> collectReportedSantriIds(
  Iterable<Map<String, dynamic>> documents, {
  required int bulan,
  required int tahun,
}) {
  return documents
      .where(
        (data) =>
            parseMonthlyReportPeriod(data['bulan']) == bulan &&
            parseMonthlyReportPeriod(data['tahun']) == tahun,
      )
      .map((data) => (data['santri_id'] ?? '').toString().trim())
      .where((id) => id.isNotEmpty)
      .toSet();
}
