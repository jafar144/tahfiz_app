class FamilyAccount {
  final String id;
  final String name;
  final String nis;
  final String kelas;
  final String jenisKelamin;
  final String? photoUrl;

  const FamilyAccount({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    required this.jenisKelamin,
    this.photoUrl,
  });

  factory FamilyAccount.fromMap(Map<Object?, Object?> map) {
    String text(String key) => map[key]?.toString().trim() ?? '';
    final photoUrl = text('photoUrl');

    return FamilyAccount(
      id: text('id'),
      name: text('name'),
      nis: text('nis'),
      kelas: text('kelas'),
      jenisKelamin: text('jenisKelamin').toUpperCase(),
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
    );
  }
}
