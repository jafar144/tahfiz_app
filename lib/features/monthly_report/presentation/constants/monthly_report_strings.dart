/// Kumpulan teks (string) statis untuk fitur Penilaian Bulanan.
///
/// Dipisah dari widget agar mudah dikelola, dipakai ulang, dan konsisten.
/// Teks yang butuh nilai dinamis disediakan sebagai static method.
class MonthlyReportStrings {
  MonthlyReportStrings._();

  // ── Umum / dipakai di beberapa halaman ──────────────────────────────
  static const penilaianBulanan = 'Penilaian Bulanan';
  static const cobaLagi = 'Coba Lagi';
  static const perkembangan = 'Perkembangan';
  static const akhlaq = 'Akhlaq';
  static const belumAdaPenilaian = 'Belum ada penilaian';

  // ── Halaman daftar santri (list) ────────────────────────────────────
  static const listEmpty = 'Belum ada santri di halaqah Anda';
  static const menungguPeriode = 'Menunggu periode penilaian';

  static String periode(String bulan, int tahun) => 'Periode: $bulan $tahun';
  static String penilaianTerbuka(int hariTersisa) =>
      'Penilaian terbuka • $hariTersisa hari tersisa';

  // ── Penilaian tertunggak (susulan) ──────────────────────────────────
  static const penilaianTertunggak = 'Penilaian tertunggak';
  static const belumDinilai = 'Belum dinilai';
  static const isiSekarang = 'Isi sekarang';

  static String tertunggakBanner(int jumlah) =>
      '$jumlah penilaian bulan lalu belum diisi';
  static String tertunggakBadge(int jumlah) => '$jumlah bln tertunggak';

  // ── Halaman riwayat / detail penilaian santri ───────────────────────
  static const riwayatPenilaian = 'Riwayat Penilaian';
  static const tambahPenilaian = 'Tambah Penilaian';
  static const editPenilaian = 'Edit Penilaian';
  static const detailEmptySubtitle =
      'Tekan "Tambah Penilaian" untuk menilai santri';
  static const windowClosedTitle = 'Belum Waktunya Menilai';
  static const windowClosedMessage =
      'Penilaian hanya dapat diinput dalam rentang 1 minggu sebelum akhir bulan.';
  static const mengerti = 'Mengerti';

  // ── Halaman input penilaian ─────────────────────────────────────────
  static const inputTitle = 'Penilaian Santri';
  static const penilaianTerakhir = 'Penilaian Terakhir';
  static const hafalanTerakhir = 'Hafalan Terakhir';
  static const hafalanHint = 'Contoh: Al-Baqarah ayat 1-20';
  static const catatanOpsional = 'Catatan (Opsional)';
  static const catatanHint = 'Tambahkan catatan...';
  static const wajibDiisi = 'Wajib diisi';
  static const pilihNilai = 'Pilih nilai';
  static const simpanPenilaian = 'Simpan Penilaian';
  static const perbaruiPenilaian = 'Perbarui Penilaian';
  static const pilihNilaiPerkembanganAkhlaq =
      'Harap pilih nilai Perkembangan dan Akhlaq';
  static const evaluasiTarget = 'Evaluasi Target Bulan Ini';
  static const evaluasiTargetHint =
      'Pilih hasil yang paling sesuai dengan capaian santri.';
  static const hasilTargetWajib = 'Harap pilih hasil target bulan ini';
  static const targetBulanDepan = 'Target Bulan Depan';
  static const targetBulanDepanHint =
      'Buat batas minimum yang realistis dan target optimum yang menantang.';
  static const targetMinimum = 'Target Minimum';
  static const targetOptimum = 'Target Optimum';
  static const targetMinimumHint = 'Contoh: Murojaah 3 halaman dengan lancar';
  static const targetOptimumHint =
      'Contoh: Menambah hafalan 5 halaman dengan lancar';
  static const berhasilDisimpan = 'Penilaian berhasil disimpan';

  // ── Kartu penilaian (riwayat santri) ────────────────────────────────
  static const nilaiKosong = '—';
  static const adaCatatan = 'Ada catatan dari ustadz';
  static const catatanUstadz = 'Catatan Ustadz';

  static String dinilaiOleh(String namaPengajar) =>
      'Dinilai oleh $namaPengajar';

  // ── Halaman penilaian milik santri ──────────────────────────────────
  static const santriEmptySubtitle =
      'Penilaian bulanan dari pengajar akan muncul di sini';
}
