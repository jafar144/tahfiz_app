class AsatidzDetail {
  final String id;
  final String name;
  final String nis;
  final String phone;
  final String jenisKelamin;
  final bool isActive;
  final String? photoUrl;

  AsatidzDetail({
    required this.id,
    required this.name,
    required this.nis,
    required this.phone,
    required this.jenisKelamin,
    required this.isActive,
    this.photoUrl,
  });
}
