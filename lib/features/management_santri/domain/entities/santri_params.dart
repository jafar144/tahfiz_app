import 'dart:io';

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
  final String? kelasFiqih;
  final String tipeKelas;
  final DateTime entryDate;
  final bool isFree; // Status Pembayaran (Gratis/Berbayar)
  final bool isActive; // Status Aktif
  final DateTime? freeUntil;
  final String? photoUrl;
  final File? localPhotoFile;
  final bool removePhoto; // Hapus foto profil yang ada saat menyimpan

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
    this.kelasFiqih,
    required this.tipeKelas,
    required this.entryDate,
    required this.isFree,
    this.isActive = true,
    this.freeUntil,
    this.photoUrl,
    this.localPhotoFile,
    this.removePhoto = false,
  });
}
