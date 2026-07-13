/// Aturan teknis penyusunan opsi bonus yang dipakai mode Suara dan Pilihan.
class QuizBonusRules {
  QuizBonusRules._();

  /// Jawaban benar + distraktor untuk tebak surah/angka.
  static const int optionCount = 6;

  /// Acuan soal nomor urut dipilih maksimal ±5 surah dari target.
  static const int orderNumberMaxReferenceDistance = 5;

  /// Lima soal INTI berturut-turut benar membuka satu soal bonus.
  static const int requiredCorrectCoreStreak = 5;
}

/// Pelacak streak bersama untuk mode Suara dan Pilihan.
class QuizBonusStreak {
  int _correctCoreAnswers = 0;

  int get count => _correctCoreAnswers;
  bool get canOfferBonus =>
      _correctCoreAnswers >= QuizBonusRules.requiredCorrectCoreStreak;

  void registerCoreAnswer({required bool correct}) {
    _correctCoreAnswers = correct ? _correctCoreAnswers + 1 : 0;
  }

  void consumeBonus() => _correctCoreAnswers = 0;
  void resetSession() => _correctCoreAnswers = 0;
}
