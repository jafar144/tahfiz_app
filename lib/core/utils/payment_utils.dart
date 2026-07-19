class PaymentUtils {
  static final DateTime firstSupportedPeriod = DateTime(2026, 2);

  /// Menormalisasi periode pembayaran agar tidak pernah sebelum Februari 2026.
  static DateTime clampToSupportedPeriod(DateTime date) {
    final period = DateTime(date.year, date.month);
    return period.isBefore(firstSupportedPeriod)
        ? firstSupportedPeriod
        : period;
  }

  /// Tahun yang tersedia di filter: mulai 2026 sampai satu tahun setelah kini.
  static List<int> availablePaymentYears({DateTime? now}) {
    final current = now ?? DateTime.now();
    final lastYear = current.year + 1 < firstSupportedPeriod.year
        ? firstSupportedPeriod.year
        : current.year + 1;
    return List.generate(
      lastYear - firstSupportedPeriod.year + 1,
      (index) => firstSupportedPeriod.year + index,
    );
  }

  /// Februari–Desember untuk 2026; tahun berikutnya menampilkan semua bulan.
  static List<int> availablePaymentMonths(int year) {
    if (year < firstSupportedPeriod.year) return const [];
    final firstMonth = year == firstSupportedPeriod.year
        ? firstSupportedPeriod.month
        : 1;
    return List.generate(13 - firstMonth, (index) => firstMonth + index);
  }

  /// Menghitung bulan pertama santri wajib membayar.
  /// - free_until null → mulai dari tanggal_masuk
  /// - free_until ada dan sudah lewat → mulai dari bulan setelah free_until
  static DateTime? resolveStartDate({
    required DateTime? freeUntil,
    required DateTime? tanggalMasuk,
  }) {
    if (tanggalMasuk == null) return null;
    final entryMonth = DateTime(tanggalMasuk.year, tanggalMasuk.month);

    if (freeUntil != null && !freeUntil.isAfter(DateTime.now())) {
      final afterFree = DateTime(freeUntil.year, freeUntil.month + 1);
      final afterFreeMonth = DateTime(afterFree.year, afterFree.month);
      return afterFreeMonth.isAfter(entryMonth) ? afterFreeMonth : entryMonth;
    }
    return entryMonth;
  }

  /// Apakah santri sudah terdaftar (dan wajib bayar/dihitung) pada [month]/[year].
  /// Santri yang tanggal_masuk-nya setelah bulan tsb dianggap belum terdaftar.
  static bool isEnrolledInMonth({
    required DateTime? tanggalMasuk,
    required int month,
    required int year,
  }) {
    if (tanggalMasuk == null) return false;
    final enrolledAt = DateTime(tanggalMasuk.year, tanggalMasuk.month);
    final target = DateTime(year, month);
    return !enrolledAt.isAfter(target);
  }

  static String getMonthName(int month) {
    const months = [
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
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}
