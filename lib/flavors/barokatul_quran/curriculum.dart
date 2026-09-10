import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';

/// Kurikulum awal agar flavor Barokatul Qur'an dapat dijalankan dan diuji.
///
/// Nama jenjang, sesi, fiqih, dan cakupan hafalan wajib diselaraskan dengan
/// keputusan lembaga sebelum aplikasi dipakai untuk data produksi.
const barokatulQuranCurriculum = InstitutionCurriculum(
  classNames: ['Tahsin', 'Tahfiz'],
  classTypes: ['Pagi', 'Sore', 'Malam'],
  memorizationByClass: {
    'Tahfiz': MemorizationScope(juz: [30]),
  },
);
