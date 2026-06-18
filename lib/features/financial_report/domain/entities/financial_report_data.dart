import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

/// Agregat data laporan keuangan untuk satu bulan terpilih.
class FinancialReportData {
  /// Bulan & tahun yang sedang ditampilkan.
  final DateTime selectedDate;

  /// Total pendapatan (jumlah seluruh pembayaran) pada bulan terpilih.
  final int totalRevenue;

  /// Total pendapatan bulan sebelumnya (untuk perbandingan tren).
  final int previousMonthRevenue;

  /// Jumlah transaksi pembayaran yang masuk pada bulan terpilih.
  final int transactionCount;

  /// Jumlah santri aktif yang wajib bayar (tidak gratis).
  final int billableCount;

  /// Jumlah santri yang sudah bayar atau berstatus gratis.
  final int paidCount;

  /// Daftar santri yang belum melakukan pembayaran pada bulan terpilih.
  final List<SantriEntity> unpaidStudents;

  /// Rincian pendapatan per kelompok (mis. Putra Sore, Putri Pagi).
  final List<RevenueGroup> groups;

  const FinancialReportData({
    required this.selectedDate,
    required this.totalRevenue,
    required this.previousMonthRevenue,
    required this.transactionCount,
    required this.billableCount,
    required this.paidCount,
    required this.unpaidStudents,
    required this.groups,
  });

  int get unpaidCount => unpaidStudents.length;

  /// Selisih pendapatan dibanding bulan lalu (positif = naik).
  int get revenueDelta => totalRevenue - previousMonthRevenue;

  /// Persentase perubahan dibanding bulan lalu. Null bila bulan lalu nol.
  double? get revenueDeltaPercent {
    if (previousMonthRevenue == 0) return null;
    return (revenueDelta / previousMonthRevenue) * 100;
  }
}

/// Rincian pendapatan satu kelompok santri (gender x sesi kelas).
class RevenueGroup {
  /// Label tampil, mis. "Putra Sore".
  final String label;

  /// Kode gender santri (L / P).
  final String gender;

  /// Sesi kelas (Pagi / Sore / Malam / Lainnya).
  final String session;

  /// Total pendapatan kelompok ini pada bulan terpilih.
  final int revenue;

  /// Jumlah transaksi pembayaran pada kelompok ini.
  final int paymentCount;

  const RevenueGroup({
    required this.label,
    required this.gender,
    required this.session,
    required this.revenue,
    required this.paymentCount,
  });
}
