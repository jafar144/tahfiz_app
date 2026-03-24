
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';

class PaymentUtils {
  static DateTime? resolveStartDate(SantriDetail detail) {
    final freeUntil = detail.freeUntil;
    final tanggalMasuk = detail.tanggalMasuk;

    if (freeUntil != null && !freeUntil.isAfter(DateTime.now())) {
      final afterFree = DateTime(freeUntil.year, freeUntil.month + 1);
      return DateTime(afterFree.year, afterFree.month);
    }

    if (tanggalMasuk != null) {
      return DateTime(tanggalMasuk.year, tanggalMasuk.month);
    }

    return null;
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
