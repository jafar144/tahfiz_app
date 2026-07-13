import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';

/// Kurikulum lembaga Khoirunnasyien.
///
/// Cakupan bersifat kumulatif. Saat materi kelas berubah, ubah file ini saja;
/// sistem progres/pembelajaran dan adapter kuis membaca sumber yang sama.
const khoirunnasyienCurriculum = InstitutionCurriculum(
  classNames: [
    'Tahsin Awwal',
    'Tahsin Akhir',
    'Mutawassith',
    'Pra Takhossus Awal',
    'Pra Takhossus Akhir',
    'Takhossus Awal',
    'Takhossus Tsani',
    'Takhossus Tsalits',
    'Takhossus Robi',
    'Takhossus Khomis',
    'Takhossus Akhir',
  ],
  classTypes: ['Pagi', 'Sore', 'Malam'],
  memorizationByClass: {
    'Mutawassith': MemorizationScope(juz: [30]),
    'Pra Takhossus Awal': MemorizationScope(
      juz: [30],
      extraSurahs: {77, 75, 74, 70, 69, 68},
    ),
    'Pra Takhossus Akhir': MemorizationScope(juz: [29, 30]),
    'Takhossus Awal': MemorizationScope(juz: [1, 2, 3, 4, 5, 29, 30]),
    'Takhossus Tsani': MemorizationScope(juz: [1, 2, 3, 4, 5, 29, 30]),
    'Takhossus Tsalits': MemorizationScope(juz: [1, 2, 3, 4, 5, 29, 30]),
    'Takhossus Robi': MemorizationScope(juz: [1, 2, 3, 4, 5, 29, 30]),
    'Takhossus Khomis': MemorizationScope(juz: [1, 2, 3, 4, 5, 29, 30]),
    'Takhossus Akhir': MemorizationScope(juz: [1, 2, 3, 4, 5, 29, 30]),
  },
  previousChallengeClass: {
    'Pra Takhossus Awal': 'Mutawassith',
    'Pra Takhossus Akhir': 'Pra Takhossus Awal',
    'Takhossus Awal': 'Pra Takhossus Akhir',
  },
);
