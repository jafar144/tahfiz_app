const syahadahVisibleDuration = Duration(days: 7);
const _wibOffset = Duration(hours: 7);

/// Apakah foto masih masuk periode tampil tujuh hari di Home Santri.
bool isSyahadahPhotoActive(DateTime createdAt, {DateTime? now}) {
  final currentTime = (now ?? DateTime.now()).toUtc();
  final expiresAt = createdAt.toUtc().add(syahadahVisibleDuration);
  return !currentTime.isAfter(expiresAt);
}

/// Jadwal pembersihan berikutnya yang akan menghapus foto ini.
///
/// Backend berjalan setiap Senin pukul 03.00 WIB dan memakai kondisi
/// `created_at < now - 7 hari`, sehingga waktu jadwal harus benar-benar
/// melewati akhir masa tampil foto.
DateTime syahadahScheduledDeletionAtUtc(DateTime createdAt, {DateTime? now}) {
  final expiresAtUtc = createdAt.toUtc().add(syahadahVisibleDuration);
  final currentTimeUtc = (now ?? DateTime.now()).toUtc();
  final thresholdUtc = currentTimeUtc.isAfter(expiresAtUtc)
      ? currentTimeUtc
      : expiresAtUtc;

  // Bentuk DateTime UTC ini sengaja dipakai sebagai representasi field waktu
  // lokal WIB agar perhitungan hari tidak bergantung zona waktu perangkat.
  final thresholdWib = thresholdUtc.add(_wibOffset);
  final daysUntilMonday =
      (DateTime.monday - thresholdWib.weekday + DateTime.daysPerWeek) %
      DateTime.daysPerWeek;
  var scheduleWib = DateTime.utc(
    thresholdWib.year,
    thresholdWib.month,
    thresholdWib.day + daysUntilMonday,
    3,
  );

  if (!scheduleWib.isAfter(thresholdWib)) {
    scheduleWib = scheduleWib.add(const Duration(days: 7));
  }

  return scheduleWib.subtract(_wibOffset);
}

/// Mengubah instant UTC menjadi representasi field waktu WIB untuk formatter.
DateTime syahadahUtcToWib(DateTime value) {
  return value.toUtc().add(_wibOffset);
}
