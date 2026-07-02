/// Mode permainan Kuis Hafalan.
///
/// - [voice]  : jawab dengan suara (dicek Whisper). Memakai energi, tanpa timer,
///              jumlah soal tetap.
/// - [choice] : pilihan ganda dari 6 opsi ayat. TANPA energi, ada timer mundur
///              60 detik untuk seluruh sesi (jumlah soal tak dibatasi).
enum QuizMode { voice, choice }

extension QuizModeX on QuizMode {
  /// Kunci stabil untuk penyimpanan (Firestore path & field).
  String get key => this == QuizMode.choice ? 'choice' : 'voice';

  /// Label singkat untuk UI.
  String get label => this == QuizMode.choice ? 'Pilihan' : 'Suara';

  bool get isVoice => this == QuizMode.voice;
  bool get isChoice => this == QuizMode.choice;

  /// Parse dari kunci tersimpan (default [voice] bila tak dikenal).
  static QuizMode fromKey(String? key) =>
      key == 'choice' ? QuizMode.choice : QuizMode.voice;
}
