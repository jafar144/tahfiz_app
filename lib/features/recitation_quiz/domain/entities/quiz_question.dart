import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_bonus.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_question_types.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

export 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_question_types.dart'
    show QuizVoiceTask;

/// Petunjuk khusus soal Suara "tebak ayat dari makna".
class MeaningToAyahPrompt {
  final String meaning;
  final String arabicHint;

  const MeaningToAyahPrompt({required this.meaning, required this.arabicHint});
}

/// Satu soal kuis: sebuah ayat [prompt] ditampilkan (teks Arab, tanpa label).
///
/// Mode suara — tugas santri tergantung [task]:
/// - [QuizVoiceTask.continueAyah]  : baca [answer] = 1-4 ayat lanjutan.
/// - [QuizVoiceTask.lastAyah]      : baca ayat terakhir surah dari ayat tampil.
/// - [QuizVoiceTask.specificAyah]  : baca ayat ke-[targetAyahNumber] surahnya.
/// - [QuizVoiceTask.meaningToAyah] : tebak dan baca ayat dari makna kosakata.
/// Bacaan dicek Whisper. [answer] bisa memuat penanda basmalah (ayat bernomor
/// 0) di depan ayat pertama surah.
///
/// Mode pilihan: santri memilih dari [options] (6 ayat teracak yang memuat
/// jawaban benar), atau — bila [trivia] terisi — menjawab soal trivia surah
/// (nama+arti / nomor urut / jumlah ayat) tentang surah dari ayat prompt.
class QuizQuestion {
  /// Ayat yang ditampilkan sebagai petunjuk.
  final Ayah prompt;

  /// Ayat-ayat target pemeriksaan (bisa diselingi basmalah pada mode suara).
  /// Kosong pada soal trivia.
  final List<Ayah> answer;

  /// Pilihan ayat untuk mode pilihan ganda (teracak, memuat [answerAyat]).
  /// Kosong pada mode suara & soal trivia.
  final List<Ayah> options;

  /// Tugas soal inti mode suara (default: lanjutkan ayat).
  final QuizVoiceTask task;

  /// Label kesulitan aktual soal ini, bukan tingkat kesulitan sesi.
  final QuizDifficulty difficulty;

  /// Terisi hanya untuk [QuizVoiceTask.meaningToAyah].
  final MeaningToAyahPrompt? meaningToAyah;

  /// Soal trivia surah (mode pilihan) tentang surah ayat [prompt]; null bila
  /// soal biasa (lanjutan ayat).
  final QuizBonusQuestion? trivia;

  /// Soal fakta atau arti kata (pilihan tunggal).
  final FactQuestion? knowledge;

  /// Soal bonus mencocokkan kosa kata.
  final VocabMatchQuestion? vocabMatch;

  const QuizQuestion({
    required this.prompt,
    required this.answer,
    this.options = const [],
    this.task = QuizVoiceTask.continueAyah,
    this.difficulty = QuizDifficulty.medium,
    this.meaningToAyah,
    this.trivia,
    this.knowledge,
    this.vocabMatch,
  });

  /// True bila soal ini soal trivia surah (mode pilihan).
  bool get isTrivia => trivia != null || vocabMatch != null;

  bool get isKnowledge => knowledge != null;

  bool get isVocabMatch => vocabMatch != null;

  bool get isMeaningToAyah =>
      task == QuizVoiceTask.meaningToAyah && meaningToAyah != null;

  /// Nomor ayat yang diminta pada tugas [QuizVoiceTask.specificAyah]
  /// (diambil dari ayat jawaban pertama).
  int get targetAyahNumber => answerAyat.isEmpty ? 0 : answerAyat.first.number;

  /// True bila jawaban memuat basmalah (dimulai dari awal surah).
  bool get hasBasmalah => answer.any((a) => a.number == 0);

  /// Ayat-ayat jawaban "sebenarnya" (tanpa penanda basmalah).
  List<Ayah> get answerAyat =>
      answer.where((a) => a.number != 0).toList(growable: false);

  /// Jumlah ayat yang harus dilanjutkan santri (basmalah tidak dihitung).
  int get answerAyahCount => answerAyat.length;

  /// Teks referensi lengkap (basmalah + ayat) untuk pencocokan bacaan.
  String get answerText => answer.map((a) => a.text).join(' ');

  /// Indeks opsi yang benar, TERURUT sesuai jawaban (mode pilihan).
  /// Contoh: jawaban 2 ayat → [indeks ayat-1, indeks ayat-2] pada [options].
  List<int> get correctOptionOrder {
    return answerAyat.map((a) {
      return options.indexWhere(
        (o) => o.surahId == a.surahId && o.number == a.number,
      );
    }).toList();
  }
}
