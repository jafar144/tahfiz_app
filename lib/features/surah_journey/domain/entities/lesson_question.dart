import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

/// Jenis soal ujian Petualangan Surah.
enum LessonTaskType {
  /// SUARA: lanjutkan bacaan dari ayat yang ditampilkan.
  voiceContinue,

  /// SUARA: baca ayat TERAKHIR surah (ayat tampil = ayat lain dari surah itu).
  voiceLastAyah,

  /// PILIHAN: soal materi/fakta surah dari halaman belajar.
  choiceFact,
}

/// Satu soal ujian surah — soal suara membawa ayat prompt+jawaban; soal
/// pilihan membawa [FactQuestion] dari bank soal materi.
class LessonQuestion {
  final LessonTaskType type;

  /// Ayat yang ditampilkan sebagai petunjuk (soal suara).
  final Ayah? prompt;

  /// Ayat jawaban yang harus dibaca (soal suara).
  final List<Ayah> answer;

  /// Soal pilihan ganda materi (tipe [LessonTaskType.choiceFact]).
  final FactQuestion? fact;

  const LessonQuestion._({
    required this.type,
    this.prompt,
    this.answer = const [],
    this.fact,
  });

  const LessonQuestion.voice({
    required LessonTaskType type,
    required Ayah prompt,
    required List<Ayah> answer,
  }) : this._(type: type, prompt: prompt, answer: answer);

  const LessonQuestion.choice(FactQuestion fact)
    : this._(type: LessonTaskType.choiceFact, fact: fact);

  bool get isVoice => type != LessonTaskType.choiceFact;
}
