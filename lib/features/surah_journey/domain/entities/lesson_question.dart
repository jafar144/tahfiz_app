import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

/// Jenis soal ujian Petualangan Surah.
enum LessonTaskType {
  /// SUARA: lanjutkan bacaan dari ayat yang ditampilkan.
  voiceContinue,

  /// SUARA: baca ayat TERAKHIR surah (ayat tampil = ayat lain dari surah itu).
  voiceLastAyah,

  /// PILIHAN: soal materi/fakta surah dari halaman belajar.
  choiceFact,

  /// Mencocokkan empat kosa kata Arab dengan artinya.
  vocabMatch,

  /// SUARA: arti Indonesia tampil; santri mengucapkan potongan Arabnya.
  vocabMeaningRecall,
}

/// Tahap penguatan kosa kata pada bagian Kosa Kata.
enum VocabLearningPhase { arabicToMeaning, mixedPractice, meaningRecall }

extension VocabLearningPhaseX on VocabLearningPhase {
  int get number => index + 1;

  String get title => switch (this) {
    VocabLearningPhase.arabicToMeaning => 'Kenali Artinya',
    VocabLearningPhase.mixedPractice => 'Latihan Campuran',
    VocabLearningPhase.meaningRecall => 'Ingat & Ucapkan',
  };
}

/// Petunjuk soal suara arti Indonesia → potongan Arab.
class VocabRecallPrompt {
  final String meaning;
  final String arabicHint;

  const VocabRecallPrompt({required this.meaning, required this.arabicHint});
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

  /// Pasangan kosa kata (tipe [LessonTaskType.vocabMatch]).
  final VocabMatchQuestion? vocabMatch;

  /// Fase latihan; null pada Ujian Akhir dan test bagian non-kosa-kata.
  final VocabLearningPhase? vocabPhase;

  /// Petunjuk khusus tipe [LessonTaskType.vocabMeaningRecall].
  final VocabRecallPrompt? vocabRecall;

  const LessonQuestion._({
    required this.type,
    this.prompt,
    this.answer = const [],
    this.fact,
    this.vocabMatch,
    this.vocabPhase,
    this.vocabRecall,
  });

  const LessonQuestion.voice({
    required LessonTaskType type,
    required Ayah prompt,
    required List<Ayah> answer,
    VocabLearningPhase? vocabPhase,
  }) : this._(
         type: type,
         prompt: prompt,
         answer: answer,
         vocabPhase: vocabPhase,
       );

  const LessonQuestion.choice(
    FactQuestion fact, {
    VocabLearningPhase? vocabPhase,
  }) : this._(
         type: LessonTaskType.choiceFact,
         fact: fact,
         vocabPhase: vocabPhase,
       );

  const LessonQuestion.match(
    VocabMatchQuestion vocabMatch, {
    VocabLearningPhase? vocabPhase,
  }) : this._(
         type: LessonTaskType.vocabMatch,
         vocabMatch: vocabMatch,
         vocabPhase: vocabPhase,
       );

  LessonQuestion.vocabRecall({
    required Ayah sourceAyah,
    required Ayah answerTarget,
    required String meaning,
    required String arabicHint,
    this.vocabPhase,
  }) : type = LessonTaskType.vocabMeaningRecall,
       prompt = sourceAyah,
       answer = [answerTarget],
       fact = null,
       vocabMatch = null,
       vocabRecall = VocabRecallPrompt(
         meaning: meaning,
         arabicHint: arabicHint,
       );

  bool get isVoice =>
      type == LessonTaskType.voiceContinue ||
      type == LessonTaskType.voiceLastAyah ||
      type == LessonTaskType.vocabMeaningRecall;

  bool get isMatch => type == LessonTaskType.vocabMatch;

  bool get isVocabRecall =>
      type == LessonTaskType.vocabMeaningRecall && vocabRecall != null;
}
