enum SantriSortBy { nis, name }

class SantriEntity {
  final String id;
  final String name;
  final String nis;
  final String kelas;
  final String? kelasFiqih;
  final String jenisKelamin;
  final bool isActive;
  final bool isFree;
  final String? pembimbing;
  final String? nomorWali;
  final String? tipeKelas;
  final String? halaqahId;
  final String? halaqahName;
  final DateTime? freeUntil;
  final DateTime? tanggalMasuk;
  final String? photoUrl;

  SantriEntity({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    this.kelasFiqih,
    required this.jenisKelamin,
    required this.isActive,
    required this.isFree,
    this.freeUntil,
    this.tanggalMasuk,
    this.pembimbing,
    this.nomorWali,
    this.tipeKelas,
    this.halaqahId,
    this.halaqahName,
    this.photoUrl,
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
      photoUrl: null,
    );
  }

  bool get hasProfilePhoto => photoUrl?.trim().isNotEmpty ?? false;

  bool get hasHalaqah => halaqahId?.trim().isNotEmpty ?? false;

  bool get hasGuardianPhone => nomorWali?.trim().isNotEmpty ?? false;
}
