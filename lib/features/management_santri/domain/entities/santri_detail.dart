class SantriDetail {
  final String id;
  final String name;
  final String nis;
  final String kelas;
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

  const SantriDetail({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
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
  });
}
