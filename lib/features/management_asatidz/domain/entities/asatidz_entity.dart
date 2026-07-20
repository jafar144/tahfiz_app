class AsatidzEntity {
  final String id;
  final String name;
  final String nis;
  final String jenisKelamin;
  final bool isActive;
  final String? photoUrl;

  AsatidzEntity({
    required this.id,
    required this.name,
    required this.nis,
    required this.jenisKelamin,
    required this.isActive,
    this.photoUrl,
  });
}
