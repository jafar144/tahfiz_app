import 'package:equatable/equatable.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_bonus.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';

/// Status keseluruhan sesi kuis.
enum QuizStatus { intro, loading, error, playing, finished }

/// Tahap soal bonus tebak surah (mode suara) setelah bacaan lolos.
enum BonusStage {
  /// Tak ada bonus (belum lolos / bonus tak tersedia).
  none,

  /// Bonus tersedia, menunggu santri menekan "Soal Bonus".
  offered,

  /// Hitung mundur berjalan, santri sedang memilih.
  running,

  /// Sudah dijawab / waktu habis — tampilkan hasil bonus.
  done,
}

/// Tahap Soal BONUS (trivia surah) pada mode PILIHAN. Selama tahap ini timer
/// sesi utama dijeda dan soal punya hitung mundur sendiri.
enum ChoiceBonusStage {
  /// Bukan soal bonus (soal lanjutan ayat biasa).
  none,

  /// Splash "Soal Bonus" sesaat sebelum soal muncul.
  intro,

  /// Soal bonus tampil, hitung mundur berjalan.
  running,

  /// Dijawab BENAR — memperlihatkan hadiah (poin & waktu gratis beranimasi ke
  /// HUD) sejenak sebelum lanjut ke soal berikutnya.
  reward,
}

/// Fase pengerjaan satu soal.
enum AnswerPhase {
  /// Menunggu santri mulai merekam.
  idle,

  /// Sedang merekam.
  recording,

  /// Audio sedang diperiksa.
  processing,

  /// Hasil percobaan sudah keluar (lolos / boleh ulang / kunci dibuka).
  revealed,
}

class RecitationQuizState extends Equatable {
  final QuizStatus status;
  final String? errorMessage;

  /// Setelan sesi aktif (mode + juz terpilih + rentang target per juz).
  final QuizSettings settings;

  /// True setelah setelan tersimpan dimuat dari penyimpanan lokal (agar UI
  /// menampilkan nilai yang benar, bukan default sesaat).
  final bool settingsLoaded;

  /// Energi kuis terkini; null bila belum dimuat.
  final QuizEnergy? energy;

  /// True selama energi sedang dimuat dari server (tampilkan skeleton).
  final bool energyLoading;

  /// Alasan sesi gagal dimulai (sekali-tampil untuk bottom sheet); null bila
  /// tidak ada. Dibersihkan oleh UI setelah ditampilkan.
  final QuizBlockReason? startBlock;

  final List<QuizQuestion> questions;
  final int currentIndex;

  final AnswerPhase phase;

  /// Percobaan ke- (1 atau 2) untuk soal saat ini.
  final int attempt;

  /// Sisa waktu (detik) berpikir per soal mode suara; 0 = tak aktif. Bila habis
  /// sebelum jawaban dikirim, soal di-skip otomatis.
  final int voiceSecondsLeft;

  /// Sisa waktu (detik) jeda berpikir sebelum Soal Bonus mulai otomatis
  /// (mode suara). 0 = tak aktif.
  final int bonusPrepSecondsLeft;

  /// Hasil percobaan terakhir (untuk menampilkan persentase segera).
  final RecitationResult? currentResult;

  /// Persentase terbaik lintas percobaan pada soal saat ini.
  final int bestPercent;

  /// Hasil percobaan terbaik (untuk koreksi saat kunci dibuka).
  final RecitationResult? bestResult;

  /// True bila soal saat ini lolos (≥80%).
  final bool passed;

  /// True bila kunci jawaban dibuka (gagal 2x) — tampilkan jawaban + koreksi.
  final bool revealAnswer;

  /// Jawaban soal saat ini yang sudah difinalisasi (skor diketahui); null bila
  /// belum final (mis. masih boleh diulang).
  final QuizAnswer? pendingAnswer;

  final List<QuizAnswer> answers;
  final QuizResult? result;

  final bool saving;
  final String? saveError;

  // ── Mode pilihan (choice) ──────────────────────────────────────────────
  /// Sisa waktu mundur (detik) untuk seluruh sesi mode pilihan.
  final int secondsLeft;

  /// Indeks opsi yang dipilih santri, TERURUT (mode pilihan). Pada soal trivia
  /// berisi satu indeks (opsi nama surah / opsi angka).
  final List<int> picks;

  /// Indeks opsi ARTI surah terpilih (soal trivia nama+arti, mode pilihan);
  /// null bila belum memilih.
  final int? meaningPick;

  /// Umpan balik sesaat soal barusan (mode pilihan): null = belum dijawab,
  /// true = benar, false = salah. Saat non-null, opsi dikunci sejenak.
  final bool? choiceCorrect;

  /// Penghitung yang naik tiap jawaban benar mendapat tambahan waktu (mode
  /// pilihan) — pemicu animasi "+N dtk" di header.
  final int timeBonusTick;

  /// Besar tambahan waktu (detik) dari jawaban benar TERAKHIR (mode pilihan),
  /// untuk ditampilkan pada chip "+N dtk".
  final int lastTimeBonus;

  // ── Mode pilihan: Soal BONUS (trivia surah) ────────────────────────────
  /// Tahap soal bonus mode pilihan saat ini (none = soal biasa).
  final ChoiceBonusStage choiceBonusStage;

  /// Sisa detik hitung mundur soal bonus mode pilihan (timer sendiri).
  final int choiceBonusSecondsLeft;

  // ── Bonus tebak surah (mode suara) ──────────────────────────────────────
  /// Soal bonus aktif; null bila tak ada.
  final QuizBonusQuestion? bonus;

  /// Tahap soal bonus saat ini.
  final BonusStage bonusStage;

  /// Sisa waktu (detik) hitung mundur soal bonus.
  final int bonusSecondsLeft;

  /// Indeks opsi surah/angka yang dipilih, TERURUT.
  final List<int> bonusPicks;

  /// Indeks opsi ARTI surah terpilih (bonus nama+arti); null bila belum.
  final int? bonusMeaningPick;

  /// Fraksi kebenaran bonus terakhir: 1 = benar penuh, 0.5 = nama+arti benar
  /// sebagian, 0 = salah/waktu habis. (Untuk teks hasil & poin setengah.)
  final double bonusFraction;

  /// Poin bonus yang barusan diperoleh (untuk ditampilkan pada tahap done).
  final int bonusEarned;

  /// Hasil soal bonus: null = belum, true = benar, false = salah/waktu habis.
  final bool? bonusCorrect;

  const RecitationQuizState({
    this.status = QuizStatus.intro,
    this.errorMessage,
    this.settings = const QuizSettings(),
    this.settingsLoaded = false,
    this.energy,
    this.energyLoading = false,
    this.startBlock,
    this.questions = const [],
    this.currentIndex = 0,
    this.phase = AnswerPhase.idle,
    this.attempt = 1,
    this.voiceSecondsLeft = 0,
    this.bonusPrepSecondsLeft = 0,
    this.currentResult,
    this.bestPercent = 0,
    this.bestResult,
    this.passed = false,
    this.revealAnswer = false,
    this.pendingAnswer,
    this.answers = const [],
    this.result,
    this.saving = false,
    this.saveError,
    this.secondsLeft = 0,
    this.picks = const [],
    this.meaningPick,
    this.choiceCorrect,
    this.timeBonusTick = 0,
    this.lastTimeBonus = 0,
    this.choiceBonusStage = ChoiceBonusStage.none,
    this.choiceBonusSecondsLeft = 0,
    this.bonus,
    this.bonusStage = BonusStage.none,
    this.bonusSecondsLeft = 0,
    this.bonusPicks = const [],
    this.bonusMeaningPick,
    this.bonusFraction = 0,
    this.bonusEarned = 0,
    this.bonusCorrect,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get total => questions.length;
  int get questionNumber => currentIndex + 1;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  /// Boleh mengulang: gagal di percobaan 1 dan kunci belum dibuka.
  bool get canRetry =>
      phase == AnswerPhase.revealed &&
      !passed &&
      attempt == 1 &&
      !revealAnswer;

  /// Boleh lanjut: soal sudah difinalisasi.
  bool get canAdvance =>
      phase == AnswerPhase.revealed && pendingAnswer != null;

  bool get isProcessing => phase == AnswerPhase.processing;
  bool get isRecording => phase == AnswerPhase.recording;

  // ── Getter mode pilihan ────────────────────────────────────────────────
  /// Total poin terkumpul sejauh ini (mode pilihan).
  int get runningPoints => answers.fold<int>(0, (acc, a) => acc + a.score);

  /// Jumlah soal yang sudah dijawab (mode pilihan tak berbatas soal).
  int get answeredCount => answers.length;

  /// Opsi terkunci selama umpan balik ditampilkan.
  bool get choiceLocked => choiceCorrect != null;

  /// True bila soal saat ini adalah Soal Bonus mode pilihan (splash / berjalan).
  bool get isChoiceBonus => choiceBonusStage != ChoiceBonusStage.none;

  /// True bila splash "Soal Bonus" sedang tampil (mode pilihan).
  bool get choiceBonusIntro => choiceBonusStage == ChoiceBonusStage.intro;

  /// True bila soal bonus sedang berjalan (hitung mundur, mode pilihan).
  bool get choiceBonusRunning => choiceBonusStage == ChoiceBonusStage.running;

  /// True bila sedang memperlihatkan hadiah Soal Bonus (mode pilihan).
  bool get choiceBonusRewardStage =>
      choiceBonusStage == ChoiceBonusStage.reward;

  /// True bila pilihan sudah lengkap: soal ayat → sesuai jumlah ayat; trivia
  /// nama+arti → kedua bagian terisi; trivia angka → satu pilihan.
  bool get choiceComplete {
    final q = currentQuestion;
    if (q == null) return false;
    final t = q.trivia;
    if (t != null) {
      if (t.isNameMeaning) return picks.isNotEmpty && meaningPick != null;
      return picks.isNotEmpty;
    }
    return picks.length == q.answerAyahCount;
  }

  // ── Getter bonus ───────────────────────────────────────────────────────
  /// True bila pilihan bonus sudah lengkap sesuai jenis soalnya.
  bool get bonusComplete {
    final b = bonus;
    if (b == null) return false;
    if (b.isNameMeaning) {
      return bonusPicks.isNotEmpty && bonusMeaningPick != null;
    }
    return bonusPicks.length == b.requiredPicks;
  }

  /// True bila soal bonus sedang aktif (hitung mundur berjalan).
  bool get bonusRunning => bonusStage == BonusStage.running;

  RecitationQuizState copyWith({
    QuizStatus? status,
    String? errorMessage,
    QuizSettings? settings,
    bool? settingsLoaded,
    QuizEnergy? energy,
    bool? energyLoading,
    QuizBlockReason? startBlock,
    List<QuizQuestion>? questions,
    int? currentIndex,
    AnswerPhase? phase,
    int? attempt,
    int? voiceSecondsLeft,
    int? bonusPrepSecondsLeft,
    RecitationResult? currentResult,
    int? bestPercent,
    RecitationResult? bestResult,
    bool? passed,
    bool? revealAnswer,
    QuizAnswer? pendingAnswer,
    List<QuizAnswer>? answers,
    QuizResult? result,
    bool? saving,
    String? saveError,
    int? secondsLeft,
    List<int>? picks,
    int? meaningPick,
    bool? choiceCorrect,
    int? timeBonusTick,
    int? lastTimeBonus,
    ChoiceBonusStage? choiceBonusStage,
    int? choiceBonusSecondsLeft,
    QuizBonusQuestion? bonus,
    BonusStage? bonusStage,
    int? bonusSecondsLeft,
    List<int>? bonusPicks,
    int? bonusMeaningPick,
    double? bonusFraction,
    int? bonusEarned,
    bool? bonusCorrect,
    bool clearError = false,
    bool clearStartBlock = false,
    bool clearCurrentResult = false,
    bool clearBestResult = false,
    bool clearPendingAnswer = false,
    bool clearSaveError = false,
    bool clearChoiceFeedback = false,
    bool clearMeaningPick = false,
    bool clearBonus = false,
    bool clearBonusCorrect = false,
    bool clearBonusMeaningPick = false,
  }) {
    return RecitationQuizState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      settings: settings ?? this.settings,
      settingsLoaded: settingsLoaded ?? this.settingsLoaded,
      energy: energy ?? this.energy,
      energyLoading: energyLoading ?? this.energyLoading,
      startBlock: clearStartBlock ? null : (startBlock ?? this.startBlock),
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      attempt: attempt ?? this.attempt,
      voiceSecondsLeft: voiceSecondsLeft ?? this.voiceSecondsLeft,
      bonusPrepSecondsLeft: bonusPrepSecondsLeft ?? this.bonusPrepSecondsLeft,
      currentResult:
          clearCurrentResult ? null : (currentResult ?? this.currentResult),
      bestPercent: bestPercent ?? this.bestPercent,
      bestResult: clearBestResult ? null : (bestResult ?? this.bestResult),
      passed: passed ?? this.passed,
      revealAnswer: revealAnswer ?? this.revealAnswer,
      pendingAnswer:
          clearPendingAnswer ? null : (pendingAnswer ?? this.pendingAnswer),
      answers: answers ?? this.answers,
      result: result ?? this.result,
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      secondsLeft: secondsLeft ?? this.secondsLeft,
      picks: picks ?? this.picks,
      meaningPick:
          clearMeaningPick ? null : (meaningPick ?? this.meaningPick),
      choiceCorrect:
          clearChoiceFeedback ? null : (choiceCorrect ?? this.choiceCorrect),
      timeBonusTick: timeBonusTick ?? this.timeBonusTick,
      lastTimeBonus: lastTimeBonus ?? this.lastTimeBonus,
      choiceBonusStage: choiceBonusStage ?? this.choiceBonusStage,
      choiceBonusSecondsLeft:
          choiceBonusSecondsLeft ?? this.choiceBonusSecondsLeft,
      bonus: clearBonus ? null : (bonus ?? this.bonus),
      bonusStage: bonusStage ?? this.bonusStage,
      bonusSecondsLeft: bonusSecondsLeft ?? this.bonusSecondsLeft,
      bonusPicks: bonusPicks ?? this.bonusPicks,
      bonusMeaningPick: clearBonusMeaningPick
          ? null
          : (bonusMeaningPick ?? this.bonusMeaningPick),
      bonusFraction: bonusFraction ?? this.bonusFraction,
      bonusEarned: bonusEarned ?? this.bonusEarned,
      bonusCorrect:
          clearBonusCorrect ? null : (bonusCorrect ?? this.bonusCorrect),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        settings,
        settingsLoaded,
        energy,
        energyLoading,
        startBlock,
        questions,
        currentIndex,
        phase,
        attempt,
        voiceSecondsLeft,
        bonusPrepSecondsLeft,
        currentResult,
        bestPercent,
        bestResult,
        passed,
        revealAnswer,
        pendingAnswer,
        answers,
        result,
        saving,
        saveError,
        secondsLeft,
        picks,
        meaningPick,
        choiceCorrect,
        timeBonusTick,
        lastTimeBonus,
        choiceBonusStage,
        choiceBonusSecondsLeft,
        bonus,
        bonusStage,
        bonusSecondsLeft,
        bonusPicks,
        bonusMeaningPick,
        bonusFraction,
        bonusEarned,
        bonusCorrect,
      ];
}
