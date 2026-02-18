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
  final DateTime? freeUntil;
  final DateTime? tanggalMasuk;

  SantriEntity({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    required this.jenisKelamin,
    required this.isActive,
    required this.isFree,
    this.freeUntil,
    this.tanggalMasuk,
    this.pembimbing,
    this.nomorWali,
    this.tipeKelas,
  });

  factory SantriEntity.dummy() {
    return SantriEntity(
      id: 'dummy_id',
      name: 'Nama Santri Dummy Panjang',
      nis: '12345678',
      kelas: 'XII-A',
      jenisKelamin: 'L',
      isActive: true,
      isFree: false,
      tanggalMasuk: DateTime.now(),
    );
  }
}
