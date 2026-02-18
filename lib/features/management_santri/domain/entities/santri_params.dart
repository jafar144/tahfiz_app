class SantriParams {
  final String name;
  final String nis;
  final String phone;
  final String jenisKelamin;
  final String birthPlace;
  final DateTime birthDate;
  final String waliName;
  final String waliPhone;
  final String kelas;
  final String tipeKelas;
  final DateTime entryDate;
  final bool isFree; // Status Pembayaran (Gratis/Berbayar)
  final DateTime? freeUntil;

  SantriParams({
    required this.name,
    required this.nis,
    required this.phone,
    required this.jenisKelamin,
    required this.birthPlace,
    required this.birthDate,
    required this.waliName,
    required this.waliPhone,
    required this.kelas,
    required this.tipeKelas,
    required this.entryDate,
    required this.isFree,
    this.freeUntil,
  });
}
