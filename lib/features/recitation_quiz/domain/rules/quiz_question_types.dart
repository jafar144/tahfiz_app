/// Tugas soal inti mode Suara.
enum QuizVoiceTask {
  /// Ayat prompt tampil; santri membaca beberapa ayat sesudahnya.
  continueAyah,

  /// Ayat prompt tampil; santri membaca ayat terakhir surah tersebut.
  lastAyah,

  /// Ayat terakhir surah tampil; santri membaca ayat ke-N yang diminta.
  specificAyah,

  /// Makna Indonesia dan nama surah tampil; santri mengingat lalu membaca ayat
  /// lengkap yang memuat kosakata tersebut.
  meaningToAyah,
}

/// Jenis pengetahuan surah yang dapat muncul sebagai soal bonus.
enum QuizBonusType { identify, neighbor, nameMeaning, orderNumber, ayahCount }

/// Sumber konten bonus Suara.
enum VoiceBonusSource { vocabularyMatch, surahKnowledge }

/// Sumber konten pada slot bonus Pilihan.
enum ChoiceBonusSource { vocabularyMatch, surahTrivia }

/// Variasi soal yang benar-benar terlihat dalam mode Pilihan.
enum ChoiceQuestionType {
  continueAyah,
  vocabularyMeaning,
  surahFact,
  vocabularyMatch,
  surahTrivia,
}
