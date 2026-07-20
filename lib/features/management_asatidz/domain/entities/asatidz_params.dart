import 'dart:io';

class AsatidzParams {
  final String name;
  final String nis;
  final String phone;
  final String jenisKelamin;
  final bool isActive;
  final String? photoUrl;
  final File? localPhotoFile;
  final bool removePhoto;

  AsatidzParams({
    required this.name,
    required this.nis,
    required this.phone,
    required this.jenisKelamin,
    required this.isActive,
    this.photoUrl,
    this.localPhotoFile,
    this.removePhoto = false,
  });
}
