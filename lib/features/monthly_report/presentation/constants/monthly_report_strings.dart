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
  static const hafalanTerakhir = 'Hafalan terakhir';
  static const hafalanHint = 'Contoh: Al-Baqarah ayat 1-20';
  static const catatanOpsional = 'Catatan (opsional)';
  static const catatanHint = 'Terlihat oleh santri';
  static const wajibDiisi = 'Wajib diisi';
  static const pilihNilai = 'Pilih nilai';
  static const simpanPenilaian = 'Simpan penilaian';
  static const perbaruiPenilaian = 'Perbarui penilaian';
  static const tidakAdaTarget = 'Belum ada target untuk bulan ini.';
  static const hasilTargetWajib = 'Pilih hasilnya';
  static const minimum = 'Minimum';
  static const optimum = 'Optimum';
  static const targetMinimum = 'Target Minimum';
  static const targetOptimum = 'Target Optimum';
  static const tidakCapai = 'Tidak capai';
  static const tanyaHukuman = 'Masukkan ke daftar hukuman?';
  static const ya = 'Ya';
  static const tidak = 'Tidak';
  static const hukumanWajib = 'Pilih Ya atau Tidak';
  static const alasanTidakDihukum = 'Alasan tidak dihukum';
  static const alasanHint = 'Contoh: sakit dua pekan';
  static const alasanHelper = 'Hanya terlihat oleh admin';
  static const alasanWajib = 'Tulis alasannya';
  static const targetMinimumHint = 'Contoh: Murojaah 3 halaman dengan lancar';
  static const targetOptimumHint =
      'Contoh: Menambah hafalan 5 halaman dengan lancar';
  static const berhasilDisimpan = 'Penilaian disimpan';

  static String penilaianPeriode(String periode) => 'Penilaian $periode';
  static String targetPeriode(String periode) => 'Target $periode';

  // ── Kartu penilaian (riwayat santri) ────────────────────────────────
  static const nilaiKosong = '—';

  static String adaCatatan(String asatidzTitle) =>
      'Ada catatan dari ${_authorLabel(asatidzTitle).toLowerCase()}';

  static String catatanPengajar(String asatidzTitle) =>
      'Catatan ${_authorLabel(asatidzTitle)}';

  static String _authorLabel(String asatidzTitle) {
    final title = asatidzTitle.trim();
    return title.isEmpty ? 'Pengajar' : title;
  }

  static String dinilaiOleh(String namaPengajar) =>
      'Dinilai oleh $namaPengajar';

  // ── Halaman penilaian milik santri ──────────────────────────────────
  static const santriEmptySubtitle =
      'Penilaian bulanan dari pengajar akan muncul di sini';
}
