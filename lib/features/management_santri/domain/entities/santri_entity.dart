class SantriEntity {
  final String id;
  final String name;
  final String nis;
  final String kelas;
  final String jenisKelamin;
  final bool isActive;
  final bool isFree;
  final String? pembimbing;
  final String? nomorWali;
  final String? tipeKelas;

  SantriEntity({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    required this.jenisKelamin,
    required this.isActive,
    required this.isFree,
    this.pembimbing,
    this.nomorWali,
    this.tipeKelas,
  });
}
