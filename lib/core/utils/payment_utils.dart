
class PaymentUtils {
  /// Menghitung bulan pertama santri wajib membayar.
  /// - free_until null → mulai dari tanggal_masuk
  /// - free_until ada dan sudah lewat → mulai dari bulan setelah free_until
  static DateTime? resolveStartDate({
    required DateTime? freeUntil,
    required DateTime? tanggalMasuk,
  }) {
    if (freeUntil != null && !freeUntil.isAfter(DateTime.now())) {
      final afterFree = DateTime(freeUntil.year, freeUntil.month + 1);
      return DateTime(afterFree.year, afterFree.month);
    }

    if (tanggalMasuk != null) {
      return DateTime(tanggalMasuk.year, tanggalMasuk.month);
    }

    return null;
  }

  /// Apakah santri sudah terdaftar (dan wajib bayar/dihitung) pada [month]/[year].
  /// Santri yang tanggal_masuk-nya setelah bulan tsb dianggap belum terdaftar.
  static bool isEnrolledInMonth({
    required DateTime? tanggalMasuk,
    required int month,
    required int year,
  }) {
    if (tanggalMasuk == null) return true;
    final enrolledAt = DateTime(tanggalMasuk.year, tanggalMasuk.month);
    final target = DateTime(year, month);
    return !enrolledAt.isAfter(target);
  }

  static String getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}
