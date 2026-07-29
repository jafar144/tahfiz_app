import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

bool isSundayFajrEligible({
  required bool isActive,
  required String gender,
  required String kelas,
}) {
  final normalizedClass = kelas.trim().toLowerCase();
  return isActive &&
      gender.trim().toUpperCase() == 'L' &&
      normalizedClass.isNotEmpty &&
      !normalizedClass.startsWith('tahsin');
}

bool isSundayFajrEligibleSantri(SantriEntity santri) {
  return isSundayFajrEligible(
    isActive: santri.isActive,
    gender: santri.jenisKelamin,
    kelas: santri.kelas,
  );
}
