class SantriEntity {
  final String id;
  final String name;
  final String nis;
  final String kelas;
  final String jenisKelamin;
  final bool isActive;
  final String? pembimbing;

  SantriEntity({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    required this.jenisKelamin,
    required this.isActive,
    this.pembimbing,
  });
}
