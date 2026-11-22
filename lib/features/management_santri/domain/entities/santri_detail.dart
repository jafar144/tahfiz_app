class SantriDetail {
  final String id;
  final String name;
  final String nis;
  final String kelas;
  final String? kelasFiqih;
  final String jenisKelamin;
  final bool isActive;
  final bool isFree;
  final String? namaWali;
  final String? nomorWali;
  final DateTime? tanggalMasuk;
  final DateTime? tanggalLahir;
  final String? tempatLahir;
  final String? tipeKelas;
  final String? pembimbing;
  final String? phone;
  final DateTime? freeUntil;
  final String? halaqahId;
  final String? halaqahName;
  final String? photoUrl;

  /// Foto asli sebelum di-crop, dipakai untuk mengatur ulang posisi foto.
  /// Kosong untuk foto lama yang diunggah sebelum fitur ini ada.
  final String? photoOriginalUrl;

  const SantriDetail({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    this.kelasFiqih,
    required this.jenisKelamin,
    required this.isActive,
    required this.isFree,
    this.freeUntil,
    this.namaWali,
    this.nomorWali,
    this.tanggalMasuk,
    this.tanggalLahir,
    this.tempatLahir,
    this.tipeKelas,
    this.pembimbing,
    this.phone,
    this.halaqahId,
    this.halaqahName,
    this.photoUrl,
    this.photoOriginalUrl,
  });
}
