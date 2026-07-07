import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_settings_store.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_bonus.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_review.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';

class RecitationQuizCubit extends Cubit<RecitationQuizState> {
  final QuizRepository repository;
  final QuizSettingsStore settingsStore;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;

  /// Path rekaman yang menunggu diperiksa; ditahan agar bisa DIKIRIM ULANG bila
  /// pengiriman gagal karena koneksi terputus (mode suara).
  String? _pendingCheckPath;

  /// Timer perpanjang lock sesi selama bermain; null bila tak bermain.
  Timer? _heartbeat;

  /// Timer mundur sesi mode pilihan (1 detik/tick). DIJEDA selama Soal Bonus.
  Timer? _choiceTimer;

  /// Timer hitung mundur Soal Bonus mode pilihan (timer sendiri).
  Timer? _choiceBonusTimer;

  /// Timer splash "Soal Bonus" sebelum soal trivia mode pilihan muncul.
  Timer? _choiceBonusIntroTimer;

  /// Timer jeda umpan balik singkat sebelum lanjut ke soal berikut (pilihan).
  Timer? _feedbackTimer;

  /// Timer hitung mundur soal bonus tebak surah (mode suara).
  Timer? _bonusTimer;

  /// Timer batas berpikir per soal (mode suara); habis → skip otomatis.
  Timer? _voiceTimer;

  /// Timer jeda "pikir dulu" sebelum bacaan diulang otomatis (percobaan 2).
  Timer? _retryTimer;

  /// Timer jeda 5 detik sebelum Soal Bonus mulai otomatis (mode suara).
  Timer? _bonusPrepTimer;

  // Batas waktu ABSOLUT (wall-clock) tiap hitung mundur. Sisa detik dihitung
  // dari selisih terhadap [DateTime.now] pada tiap tick — BUKAN dengan
  // mengurangi 1 per tick. Ini penting agar timer tetap akurat saat aplikasi
  // sempat di-background: OS menangguhkan event loop sehingga banyak tick
  // terlewat, tapi begitu satu tick jalan lagi sisa waktu langsung benar.
  DateTime? _choiceDeadline;
  DateTime? _choiceBonusDeadline;
  DateTime? _voiceDeadline;
  DateTime? _bonusDeadline;
  DateTime? _bonusPrepDeadline;
  DateTime? _retryDeadline;

  /// True selama batch soal tambahan mode pilihan sedang disusun (mencegah
  /// penyambungan ganda yang berjalan bersamaan).
  bool _toppingUp = false;

  /// Sumber acak untuk menyusun soal bonus.
  final Random _rng = Random();

  /// True bila sesi ini sedang memegang lock (perlu dilepas saat keluar).
  bool _holdsLock = false;

  /// Jumlah Soal Bonus yang sudah ditawarkan pada sesi berjalan (untuk batas
  /// TOTAL [QuizConfig.voiceBonusMaxPerSession]).
  int _bonusesOffered = 0;

  /// Indeks soal terakhir yang menampilkan Soal Bonus (untuk menjaga jarak
  /// antar-bonus agar tersebar). -1 = belum ada.
  int _lastBonusIndex = -1;

  // Semua konstanta gameplay (jumlah soal, timer, poin, ambang, saklar energi)
  // ada di [QuizConfig] — satu tempat untuk disetel.

  /// True bila user saat ini admin → selalu melewati energi/lock (seolah
  /// [QuizConfig.enforceEnergy] false), tanpa mengubah perilaku asatidz & santri.
  bool _isAdmin = false;

  /// Sudah pernah menanyakan role admin ke repo (agar tak berulang).
  bool _roleResolved = false;

  /// Energi & lock hanya berlaku pada mode SUARA, bila master switch aktif, dan
  /// user bukan admin. Mode pilihan tak pernah memakai energi.
  bool get _enforceEnergy =>
      QuizConfig.enforceEnergy && !_isAdmin && state.settings.mode.isVoice;

  RecitationQuizCubit(this.repository, this.settingsStore)
    : super(const RecitationQuizState());

  /// Sisa detik menuju [deadline], dibulatkan KE ATAS agar hitung mundur mulai
  /// dari angka penuh dan menyentuh 0 tepat saat deadline lewat. Tak pernah
  /// negatif.
  int _secondsLeftUntil(DateTime deadline) {
    final ms = deadline.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  }

  /// Inisialisasi layar: muat setelan tersimpan lalu energi terkini.
  Future<void> init() async {
    final saved = await settingsStore.load();
    emit(state.copyWith(settings: saved, settingsLoaded: true));
    await loadEnergy();
  }

  /// Perbarui setelan draft (dari layar intro) + simpan ke penyimpanan lokal.
  void setSettings(QuizSettings settings) {
    emit(state.copyWith(settings: settings));
    unawaited(settingsStore.save(settings));
  }

  /// Kembali ke layar intro tanpa menutup halaman kuis (mis. tekan back saat
  /// bermain). Hentikan timer, lepas lock, dan segarkan energi.
  Future<void> backToIntro() async {
    _choiceTimer?.cancel();
    _choiceBonusTimer?.cancel();
    _choiceBonusTimer = null;
    _choiceBonusIntroTimer?.cancel();
    _choiceBonusIntroTimer = null;
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _bonusTimer?.cancel();
    _bonusTimer = null;
    _voiceTimer?.cancel();
    _voiceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _bonusPrepTimer?.cancel();
    _bonusPrepTimer = null;
    // Reset UI dulu agar kembali ke intro terasa instan (penting saat offline:
    // pelepasan lock ke server bisa lambat/timeout). Lepas lock di latar.
    emit(
      RecitationQuizState(
        settings: state.settings,
        settingsLoaded: state.settingsLoaded,
        energy: state.energy,
      ),
    );
    unawaited(_releaseSession());
    await loadEnergy();
  }

  /// Resolusi status admin sekali di awal (dipanggil sebelum cek energi).
  Future<void> _ensureRoleResolved() async {
    if (_roleResolved) return;
    _isAdmin = await repository.isCurrentUserAdmin();
    _roleResolved = true;
  }

  /// Muat energi terkini untuk ditampilkan di layar intro.
  Future<void> loadEnergy() async {
    await _ensureRoleResolved();
    // Testing / admin: tampilkan energi penuh & jangan panggil server.
    if (!_enforceEnergy) {
      emit(
        state.copyWith(
          energy: const QuizEnergy(current: 5, max: 5),
          energyLoading: false,
        ),
      );
      return;
    }
    emit(state.copyWith(energyLoading: true));
    final res = await repository.getEnergy();
    res.fold(
      ifLeft: (_) => emit(state.copyWith(energyLoading: false)),
      ifRight: (e) => emit(state.copyWith(energy: e, energyLoading: false)),
    );
  }

  /// Mulai / mulai ulang sesi dengan [settings] terpilih: susun 10 soal baru.
  /// Mengambil lock 1-user + memotong 1 energi (server-side); hanya berlaku
  /// bila sesi benar-benar berhasil dimulai.
  Future<void> start(QuizSettings settings) async {
    await _ensureRoleResolved();
    // Ingat setelan terakhir yang dipakai untuk sesi berikutnya.
    unawaited(settingsStore.save(settings));
    // Layar untuk kembali bila gagal mulai (intro, atau result saat "Main Lagi").
    final backStatus = state.status == QuizStatus.finished
        ? QuizStatus.finished
        : QuizStatus.intro;

    emit(
      state.copyWith(
        status: QuizStatus.loading,
        settings: settings,
        clearStartBlock: true,
      ),
    );

    // Susun soal dulu (lokal, tanpa biaya) sebelum menyentuh lock/energi.
    final res = await repository.generateQuestions(
      count: settings.mode.isChoice
          ? QuizConfig.choicePoolCount
          : QuizConfig.voiceQuestionCount,
      settings: settings,
    );

    await res.fold(
      ifLeft: (f) async => emit(
        state.copyWith(status: QuizStatus.error, errorMessage: f.message),
      ),
      ifRight: (qs) async {
        // Mode pilihan: tanpa energi/lock, langsung mulai + timer mundur.
        if (settings.mode.isChoice) {
          _enterChoicePlaying(settings, qs);
          return;
        }

        // Testing / admin (mode suara): lewati lock & energi sepenuhnya.
        if (!_enforceEnergy) {
          _enterPlaying(settings, qs, state.energy);
          return;
        }

        final started = await repository.startSession();
        await started.fold(
          ifLeft: (f) async {
            final reason = f is QuizBlockedFailure
                ? f.reason
                : QuizBlockReason.unknown;
            if (reason == QuizBlockReason.noEnergy) {
              // Energi habis → segarkan; tombol menonaktif sendiri.
              final refreshed = await repository.getEnergy();
              emit(
                state.copyWith(
                  status: backStatus,
                  energy: refreshed.fold(
                    ifLeft: (_) => state.energy,
                    ifRight: (e) => e,
                  ),
                ),
              );
            } else {
              // Sibuk / kuota Whisper / lain → bottom sheet via startBlock.
              emit(state.copyWith(status: backStatus, startBlock: reason));
            }
          },
          ifRight: (energy) async => _enterPlaying(settings, qs, energy),
        );
      },
    );
  }

  /// Masuk fase bermain + mulai heartbeat lock.
  void _enterPlaying(
    QuizSettings settings,
    List<QuizQuestion> questions,
    QuizEnergy? energy,
  ) {
    _bonusesOffered = 0;
    _lastBonusIndex = -1;
    emit(
      RecitationQuizState(
        status: QuizStatus.playing,
        settings: settings,
        energy: energy,
        questions: questions,
        phase: AnswerPhase.idle,
        voiceSecondsLeft: QuizConfig.voiceQuestionSeconds,
      ),
    );
    _startHeartbeat();
    _startVoiceTimer();
  }

  /// Detik berpikir untuk sebuah soal suara MENURUT panjang ayat jawaban:
  /// pendek → 30, sedang → 45, panjang → 60 detik. Panjang diukur dari jumlah
  /// kata ayat TERPANJANG di jawaban (abaikan penanda basmalah bernomor 0).
  int _voiceSecondsFor(QuizQuestion? q) {
    if (q == null) return QuizConfig.voiceQuestionSeconds;
    var maxWords = 0;
    for (final a in q.answer) {
      if (a.number == 0) continue; // penanda basmalah, bukan ayat
      final w = a.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((x) => x.isNotEmpty)
          .length;
      if (w > maxWords) maxWords = w;
    }
    if (maxWords <= QuizConfig.voiceShortAyahMaxWords) {
      return QuizConfig.voiceShortSeconds;
    }
    if (maxWords <= QuizConfig.voiceMediumAyahMaxWords) {
      return QuizConfig.voiceMediumSeconds;
    }
    return QuizConfig.voiceLongSeconds;
  }

  /// Mulai/ulang hitung mundur berpikir untuk soal suara saat ini.
  void _startVoiceTimer() {
    _voiceTimer?.cancel();
    final seconds = _voiceSecondsFor(state.currentQuestion);
    emit(state.copyWith(voiceSecondsLeft: seconds));
    _voiceDeadline = DateTime.now().add(Duration(seconds: seconds));
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeftUntil(_voiceDeadline!);
      if (left <= 0) {
        _voiceTimer?.cancel();
        emit(state.copyWith(voiceSecondsLeft: 0));
        _skipOnTimeout();
      } else {
        emit(state.copyWith(voiceSecondsLeft: left));
      }
    });
  }

  /// Waktu berpikir habis → hentikan rekaman bila ada, catat soal 0 poin, lanjut.
  Future<void> _skipOnTimeout() async {
    // Hanya berlaku bila masih pada fase menjawab (belum dikirim/dinilai).
    if (state.phase != AnswerPhase.idle &&
        state.phase != AnswerPhase.recording) {
      return;
    }
    if (state.phase == AnswerPhase.recording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    final skipped = QuizAnswer(
      questionIndex: state.currentIndex,
      score: 0,
      attempts: state.attempt,
      passed: false,
    );
    await _commitVoiceAnswer(skipped);
  }

  void _startHeartbeat() {
    if (!_enforceEnergy) return;
    _holdsLock = true;
    _heartbeat?.cancel();
    // Kegagalan heartbeat (mis. koneksi terputus sesaat) diabaikan agar tak
    // memunculkan error tak tertangani; lease server tetap terjaga oleh tick
    // berikutnya saat online kembali.
    _heartbeat = Timer.periodic(
      QuizConfig.heartbeatInterval,
      (_) => repository.heartbeat().catchError((_) {}),
    );
  }

  /// Lepas lock + hentikan heartbeat (dipanggil saat selesai / keluar).
  Future<void> _releaseSession() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    if (_holdsLock) {
      _holdsLock = false;
      // Best-effort: offline/gagal diabaikan (lease server kedaluwarsa sendiri),
      // dengan timeout agar tak menggantung.
      try {
        await repository.endSession().timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  // ── Mode pilihan (choice) ──────────────────────────────────────────────

  /// Masuk fase bermain mode pilihan + mulai timer mundur.
  void _enterChoicePlaying(
    QuizSettings settings,
    List<QuizQuestion> questions,
  ) {
    _toppingUp = false;
    emit(
      RecitationQuizState(
        status: QuizStatus.playing,
        settings: settings,
        questions: questions,
        secondsLeft: QuizConfig.choiceDurationSeconds,
        picks: const [],
      ),
    );
    // Soal pertama selalu soal biasa (posisi 1 bukan kelipatan interval), tapi
    // tetap dijaga: bila entah bagaimana trivia, masuk alur Soal Bonus.
    if (questions.isNotEmpty && questions.first.isTrivia) {
      _enterChoiceTrivia();
    } else {
      _startChoiceTimer();
    }
  }

  void _startChoiceTimer() {
    _choiceTimer?.cancel();
    // (Re)mulai dari sisa detik saat ini — juga dipakai untuk MELANJUTKAN timer
    // sesi setelah Soal Bonus (yang menjedanya) dengan sisa waktu yang tersimpan.
    _choiceDeadline = DateTime.now().add(Duration(seconds: state.secondsLeft));
    _choiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeftUntil(_choiceDeadline!);
      if (left <= 0) {
        _choiceTimer?.cancel();
        emit(state.copyWith(secondsLeft: 0));
        _finishChoice();
      } else {
        emit(state.copyWith(secondsLeft: left));
      }
    });
  }

  /// Ketuk sebuah opsi (ayat / nama surah / angka): tambah bila belum dipilih,
  /// atau lepas bila diketuk lagi (selama belum dikunci). Soal 1-pilihan
  /// langsung dievaluasi; nama+arti menunggu kedua bagian + tombol "Jawab".
  void pickOption(int optionIndex) {
    if (state.status != QuizStatus.playing || state.choiceLocked) return;
    final q = state.currentQuestion;
    if (q == null) return;

    final trivia = q.trivia;

    // Soal trivia: pilihan tunggal — ketuk lagi melepas, ketuk lain memindah.
    if (trivia != null) {
      if (state.picks.contains(optionIndex)) {
        emit(state.copyWith(picks: const []));
        return;
      }
      final picks = [optionIndex];
      emit(state.copyWith(picks: picks));
      // Nama+arti: tunggu bagian arti + tombol "Jawab"; angka: langsung nilai.
      if (!trivia.needsSubmit) _evaluateChoice(picks);
      return;
    }

    final required = q.answerAyahCount;
    final picks = [...state.picks];

    if (picks.contains(optionIndex)) {
      picks.remove(optionIndex); // lepas pilihan
      emit(state.copyWith(picks: picks));
      return;
    }
    if (picks.length >= required) return; // sudah penuh

    picks.add(optionIndex);
    emit(state.copyWith(picks: picks));

    // Soal 1 ayat: langsung nilai (cepat). Multi-ayat: tunggu tombol "Jawab".
    if (required == 1) _evaluateChoice(picks);
  }

  /// Pilih/lepas opsi ARTI surah (soal trivia nama+arti, mode pilihan).
  void pickMeaning(int optionIndex) {
    if (state.status != QuizStatus.playing || state.choiceLocked) return;
    if (state.currentQuestion?.trivia?.isNameMeaning != true) return;
    if (state.meaningPick == optionIndex) {
      emit(state.copyWith(clearMeaningPick: true));
    } else {
      emit(state.copyWith(meaningPick: optionIndex));
    }
  }

  /// Konfirmasi jawaban multi-bagian (dipakai tombol "Jawab").
  void submitChoice() {
    if (state.choiceLocked || !state.choiceComplete) return;
    _evaluateChoice(state.picks);
  }

  void _evaluateChoice(List<int> picks) {
    final q = state.currentQuestion!;
    final trivia = q.trivia;

    final bool correct; // dapat poin (untuk umpan balik & sound)
    final int points;
    final int timeBonus;
    if (trivia != null) {
      // Soal BONUS: hitung mundur sendiri berhenti; benar → +poin & +waktu
      // TETAP ke sesi utama (nama+arti benar sebagian → setengahnya).
      _choiceBonusTimer?.cancel();
      final double fraction;
      if (trivia.isNameMeaning) {
        final name = trivia.nameCorrect(picks.isNotEmpty ? picks.first : null);
        final meaning = trivia.meaningCorrect(state.meaningPick);
        fraction = (name ? 0.5 : 0.0) + (meaning ? 0.5 : 0.0);
      } else {
        fraction = trivia.numberCorrect(picks.isNotEmpty ? picks.first : null)
            ? 1.0
            : 0.0;
      }
      points = (QuizConfig.choiceTriviaPoints * fraction).round();
      timeBonus = (QuizConfig.choiceTriviaTimeBonus * fraction).round();
      correct = points > 0;
    } else {
      // Soal biasa: poin 4n+6, tambahan waktu n+1 (n = jumlah ayat diminta).
      final n = q.answerAyahCount;
      correct = listEquals(picks, q.correctOptionOrder);
      points = correct ? QuizConfig.choicePointsFor(n) : 0;
      timeBonus = correct ? QuizConfig.choiceTimeBonusFor(n) : 0;
    }

    final answer = QuizAnswer(
      questionIndex: state.currentIndex,
      score: points,
      attempts: 1,
      passed: points > 0,
    );

    // Soal Bonus terjawab BENAR → tahap HADIAH: tahan sejenak & animasikan
    // poin/waktu gratis ke HUD sebelum lanjut. Selain itu (soal biasa, atau
    // bonus salah/habis) → umpan balik singkat biasa.
    final bonusReward = trivia != null && points > 0;

    final reviewItem = _choiceReview(
      q,
      picks,
      state.meaningPick,
      correct,
      points,
    );
    emit(
      state.copyWith(
        choiceCorrect: correct,
        answers: [...state.answers, answer],
        review: [...state.review, reviewItem],
        secondsLeft: state.secondsLeft + timeBonus,
        lastTimeBonus: timeBonus,
        timeBonusTick: timeBonus > 0
            ? state.timeBonusTick + 1
            : state.timeBonusTick,
        choiceBonusStage: bonusReward
            ? ChoiceBonusStage.reward
            : (trivia != null
                  ? ChoiceBonusStage.running
                  : state.choiceBonusStage),
      ),
    );
    // Bonus waktu → geser deadline sesi utama agar tambahan waktu ikut terhitung
    // pada timer yang sedang berjalan (soal biasa). Untuk Soal Bonus, timer sesi
    // sedang dijeda; deadline akan dihitung ulang dari secondsLeft saat lanjut.
    if (timeBonus > 0 && _choiceDeadline != null) {
      _choiceDeadline = _choiceDeadline!.add(Duration(seconds: timeBonus));
    }
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      bonusReward
          ? QuizConfig.choiceBonusReward
          : QuizConfig.choiceFeedbackDelay,
      _advanceChoice,
    );
  }

  void _advanceChoice() {
    if (state.status != QuizStatus.playing) return; // waktu mungkin sudah habis
    final wasTrivia = state.currentQuestion?.isTrivia == true;
    final next = state.currentIndex + 1;
    if (next >= state.questions.length) {
      // Pool habis lebih dulu padahal sesi dibatasi WAKTU: seharusnya sudah
      // disambung oleh _maybeTopUpChoiceQuestions. Bila belum sempat (data
      // terbatas / penyusunan gagal), selesaikan apa adanya sebagai pengaman.
      _finishChoice();
      return;
    }
    final nextIsTrivia = state.questions[next].isTrivia;
    emit(
      state.copyWith(
        currentIndex: next,
        picks: const [],
        clearMeaningPick: true,
        clearChoiceFeedback: true,
        choiceBonusStage: ChoiceBonusStage.none,
        choiceBonusSecondsLeft: 0,
      ),
    );
    if (nextIsTrivia) {
      _enterChoiceTrivia();
    } else if (wasTrivia) {
      // Keluar dari Soal Bonus → jalankan lagi timer sesi utama.
      _startChoiceTimer();
    }
    // Sisa soal menipis → sambung batch baru lebih dulu agar tak kehabisan.
    _maybeTopUpChoiceQuestions();
  }

  /// Bila sisa soal (dari posisi saat ini) ≤ [QuizConfig.choiceTopUpThreshold],
  /// susun satu batch soal pilihan baru dan sambung ke daftar. Berjalan di latar
  /// (tak menunda transisi soal) dan dijaga agar tak menyusun dua batch
  /// bersamaan. Sesi mode pilihan jadi praktis tak terbatas — hanya waktu yang
  /// mengakhirinya.
  Future<void> _maybeTopUpChoiceQuestions() async {
    if (_toppingUp || !state.settings.mode.isChoice) return;
    final remaining = state.questions.length - state.currentIndex - 1;
    if (remaining > QuizConfig.choiceTopUpThreshold) return;

    _toppingUp = true;
    try {
      final res = await repository.generateQuestions(
        count: QuizConfig.choicePoolCount,
        settings: state.settings,
      );
      res.fold(
        ifLeft: (_) {}, // gagal menyusun → biarkan; pengaman di _advanceChoice.
        ifRight: (qs) {
          // Hanya sambung bila masih bermain mode pilihan (hindari balapan
          // dengan keluar/selesai sesi).
          if (qs.isNotEmpty &&
              state.status == QuizStatus.playing &&
              state.settings.mode.isChoice) {
            emit(state.copyWith(questions: [...state.questions, ...qs]));
          }
        },
      );
    } finally {
      _toppingUp = false;
    }
  }

  /// Masuk Soal Bonus mode pilihan: JEDA timer sesi utama, tampilkan splash
  /// "Soal Bonus" sesaat, lalu jalankan hitung mundur soal bonus (timer sendiri).
  void _enterChoiceTrivia() {
    _choiceTimer?.cancel(); // jeda timer sesi utama
    emit(
      state.copyWith(
        choiceBonusStage: ChoiceBonusStage.intro,
        choiceBonusSecondsLeft: QuizConfig.choiceTriviaSeconds,
        picks: const [],
        clearMeaningPick: true,
        clearChoiceFeedback: true,
      ),
    );
    _choiceBonusIntroTimer?.cancel();
    _choiceBonusIntroTimer = Timer(
      QuizConfig.choiceTriviaIntro,
      _startChoiceBonusTimer,
    );
  }

  void _startChoiceBonusTimer() {
    if (state.status != QuizStatus.playing) return;
    emit(state.copyWith(choiceBonusStage: ChoiceBonusStage.running));
    _choiceBonusTimer?.cancel();
    _choiceBonusDeadline = DateTime.now().add(
      Duration(seconds: state.choiceBonusSecondsLeft),
    );
    _choiceBonusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeftUntil(_choiceBonusDeadline!);
      if (left <= 0) {
        _choiceBonusTimer?.cancel();
        emit(state.copyWith(choiceBonusSecondsLeft: 0));
        // Waktu bonus habis → nilai apa adanya (umumnya 0 poin), lalu lanjut.
        _evaluateChoice(state.picks);
      } else {
        emit(state.copyWith(choiceBonusSecondsLeft: left));
      }
    });
  }

  Future<void> _finishChoice() async {
    _choiceTimer?.cancel();
    _choiceBonusTimer?.cancel();
    _choiceBonusIntroTimer?.cancel();
    _feedbackTimer?.cancel();
    if (state.status == QuizStatus.finished) return; // hindari finalisasi ganda

    final result = QuizResult(
      answers: state.answers,
      questionCount: state.answers.length,
      mode: QuizMode.choice,
    );
    emit(
      state.copyWith(
        status: QuizStatus.finished,
        result: result,
        saving: true,
        clearChoiceFeedback: true,
        clearSaveError: true,
      ),
    );

    final save = await repository.saveAttempt(
      mode: QuizMode.choice,
      score: result.leaderboardScore,
      questionScores: result.scores,
      juz: state.settings.sortedJuz,
    );
    save.fold(
      ifLeft: (f) => emit(state.copyWith(saving: false, saveError: f.message)),
      ifRight: (_) => emit(state.copyWith(saving: false)),
    );
  }

  /// Bersihkan penanda blokir setelah bottom sheet ditampilkan.
  void clearStartBlock() {
    if (state.startBlock != null) emit(state.copyWith(clearStartBlock: true));
  }

  Future<void> startRecording() async {
    if (state.currentQuestion == null) return;
    try {
      if (!await _recorder.hasPermission()) {
        emit(
          state.copyWith(
            errorMessage: 'Izin mikrofon ditolak. Aktifkan di pengaturan.',
          ),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/quiz_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recordPath = path;
      emit(state.copyWith(phase: AnswerPhase.recording, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal memulai rekaman: $e'));
    }
  }

  /// Hentikan rekaman lalu periksa terhadap ayat jawaban.
  Future<void> stopAndCheck() async {
    final q = state.currentQuestion;
    if (q == null) return;
    // Jawaban dikirim → hentikan hitung mundur berpikir.
    _voiceTimer?.cancel();
    try {
      final stopped = await _recorder.stop();
      final path = stopped ?? _recordPath;
      if (path == null) {
        emit(
          state.copyWith(
            phase: AnswerPhase.idle,
            errorMessage: 'Rekaman tidak tersimpan.',
          ),
        );
        return;
      }
      await _submitForCheck(path);
    } catch (e) {
      emit(
        state.copyWith(
          phase: AnswerPhase.idle,
          errorMessage: 'Gagal memproses bacaan: $e',
        ),
      );
    }
  }

  /// Kirim rekaman [path] ke server untuk diperiksa. Dipakai saat menghentikan
  /// rekaman maupun saat "Kirim Ulang" setelah koneksi pulih.
  Future<void> _submitForCheck(String path) async {
    final q = state.currentQuestion;
    if (q == null) return;
    _pendingCheckPath = path;
    emit(
      state.copyWith(
        phase: AnswerPhase.processing,
        clearError: true,
        connectionLost: false,
      ),
    );

    final res = await repository.checkAnswer(
      answerAyat: q.answer,
      audioFilePath: path,
      mimeType: 'audio/mp4',
    );
    res.fold(
      ifLeft: (f) {
        if (f is NetworkFailure) {
          // Koneksi terputus → tahan rekaman & tampilkan sheet "sambungkan
          // lagi". Tetap di fase processing agar rekaman siap dikirim ulang.
          emit(state.copyWith(connectionLost: true));
        } else {
          emit(
            state.copyWith(phase: AnswerPhase.idle, errorMessage: f.message),
          );
        }
      },
      ifRight: _applyResult,
    );
  }

  /// Kirim ulang rekaman terakhir setelah koneksi pulih (dipicu sheet offline).
  void retryCheck() {
    final path = _pendingCheckPath;
    if (path == null) return;
    unawaited(_submitForCheck(path));
  }

  void _applyResult(RecitationResult result) {
    final pct = result.accuracyPercent;
    final best = pct > state.bestPercent ? pct : state.bestPercent;
    final bestResult = pct >= state.bestPercent ? result : state.bestResult;

    // Gagal (<80%) di percobaan 1 → beri kesempatan ulang, belum difinalisasi.
    if (pct < QuizConfig.passThreshold && state.attempt == 1) {
      emit(
        state.copyWith(
          phase: AnswerPhase.revealed,
          currentResult: result,
          bestPercent: best,
          bestResult: bestResult,
          passed: false,
          revealAnswer: false,
          retrySecondsLeft: QuizConfig.retryPrepSeconds,
        ),
      );
      // Beri jeda "pikir dulu"; di akhir hitungan, bacaan diulang otomatis.
      _startRetryTimer();
      return;
    }

    // Finalisasi: lolos, atau gagal 2x.
    final bool passed = pct >= QuizConfig.passThreshold;
    final bool reveal = !passed; // gagal 2x → buka kunci
    final int score = passed
        ? (pct > QuizConfig.perfectThreshold ? 100 : pct)
        : best; // gagal 2x → persentase terbaik dari 2 percobaan

    final pending = QuizAnswer(
      questionIndex: state.currentIndex,
      score: score,
      attempts: state.attempt,
      passed: passed,
      bestResult: passed ? result : bestResult,
    );

    // Lolos → siapkan soal bonus (tebak surah / trivia) bila bisa disusun, TAPI
    // hanya tiap kelipatan soal & dibatasi beberapa kali per sesi supaya santri
    // fokus merekam bacaan. Fokus tebakan = surah yang BARUSAN DIBACA.
    final bonusSlot =
        passed &&
        _bonusesOffered < QuizConfig.voiceBonusMaxPerSession &&
        (state.currentIndex - _lastBonusIndex) >=
            QuizConfig.voiceBonusEveryNQuestions;
    final bonus = bonusSlot
        ? QuizBonusQuestion.generate(
            readSurahs: state.currentQuestion!.answerAyat
                .map((a) => a.surahId)
                .toList(),
            allowed: _allowedSurahs(state.settings),
            rng: _rng,
          )
        : null;
    if (bonus != null) {
      _bonusesOffered++;
      _lastBonusIndex = state.currentIndex;
    }

    emit(
      state.copyWith(
        phase: AnswerPhase.revealed,
        currentResult: result,
        bestPercent: best,
        bestResult: bestResult,
        passed: passed,
        revealAnswer: reveal,
        pendingAnswer: pending,
        bonus: bonus,
        bonusStage: bonus != null ? BonusStage.offered : BonusStage.none,
        bonusSecondsLeft: 0,
        bonusPrepSecondsLeft: bonus != null ? QuizConfig.bonusPrepSeconds : 0,
        bonusPicks: const [],
        bonusFraction: 0,
        bonusEarned: 0,
        clearBonus: bonus == null,
        clearBonusCorrect: true,
        clearBonusMeaningPick: true,
      ),
    );

    // Lolos + ada bonus → beri jeda berpikir, lalu Soal Bonus mulai otomatis.
    if (bonus != null) _startBonusPrep();
  }

  /// Hitung mundur 5 detik jeda berpikir; di akhir, Soal Bonus mulai otomatis.
  void _startBonusPrep() {
    _bonusPrepTimer?.cancel();
    _bonusPrepDeadline = DateTime.now().add(
      Duration(seconds: state.bonusPrepSecondsLeft),
    );
    _bonusPrepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeftUntil(_bonusPrepDeadline!);
      if (left <= 0) {
        _bonusPrepTimer?.cancel();
        emit(state.copyWith(bonusPrepSecondsLeft: 0));
        startBonus();
      } else {
        emit(state.copyWith(bonusPrepSecondsLeft: left));
      }
    });
  }

  /// Hitung mundur jeda "pikir dulu"; di akhir, bacaan diulang otomatis.
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryDeadline = DateTime.now().add(
      Duration(seconds: state.retrySecondsLeft),
    );
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeftUntil(_retryDeadline!);
      if (left <= 0) {
        _retryTimer?.cancel();
        emit(state.copyWith(retrySecondsLeft: 0));
        if (state.canRetry) retry();
      } else {
        emit(state.copyWith(retrySecondsLeft: left));
      }
    });
  }

  /// Ulangi soal (percobaan ke-2) — otomatis saat jeda habis, atau ditekan
  /// santri lebih awal.
  void retry() {
    _retryTimer?.cancel();
    emit(
      state.copyWith(
        phase: AnswerPhase.idle,
        attempt: 2,
        passed: false,
        revealAnswer: false,
        retrySecondsLeft: 0,
        clearCurrentResult: true,
      ),
    );
    // Percobaan baru → hitung mundur berpikir dimulai lagi.
    _startVoiceTimer();
  }

  // ── Bonus tebak surah (mode suara) ─────────────────────────────────────

  /// Himpunan surah yang tercakup rentang target (agar soal bonus tak overflow
  /// keluar dari juz/rentang yang dipilih).
  Set<int> _allowedSurahs(QuizSettings s) {
    final set = <int>{};
    for (final j in s.sortedJuz) {
      if (!QuizJuz.isSupported(j)) continue;
      if (QuizJuz.supportsCustomRange(j)) {
        // Juz "surah utuh": surah awal terpilih s.d. surah terakhir juz.
        for (var su = s.startSurahFor(j); su <= QuizJuz.lastSurah(j); su++) {
          set.add(su);
        }
      } else {
        // Juz "rentang ayat": surah-surah pembentuk segmen.
        for (final seg in QuizJuz.ayahSegments(j)) {
          set.add(seg.$1);
        }
      }
    }
    return set;
  }

  /// Mulai soal bonus (ditekan santri) → jalankan hitung mundur (durasi soal).
  void startBonus() {
    final b = state.bonus;
    if (b == null || state.bonusStage != BonusStage.offered) return;
    _bonusPrepTimer?.cancel();
    emit(
      state.copyWith(
        bonusStage: BonusStage.running,
        bonusSecondsLeft: b.durationSeconds,
        bonusPrepSecondsLeft: 0,
        bonusPicks: const [],
        bonusFraction: 0,
        clearBonusCorrect: true,
        clearBonusMeaningPick: true,
      ),
    );
    _bonusTimer?.cancel();
    _bonusDeadline = DateTime.now().add(Duration(seconds: b.durationSeconds));
    _bonusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _secondsLeftUntil(_bonusDeadline!);
      if (left <= 0) {
        emit(state.copyWith(bonusSecondsLeft: 0));
        _finishBonus(timedOut: true);
      } else {
        emit(state.copyWith(bonusSecondsLeft: left));
      }
    });
  }

  /// Pilih/lepas opsi surah/angka. Soal 1-pilihan langsung dinilai; identify
  /// multi & nama+arti menunggu tombol "Jawab".
  void pickBonus(int optionIndex) {
    if (state.bonusStage != BonusStage.running) return;
    final b = state.bonus;
    if (b == null) return;
    final picks = [...state.bonusPicks];
    if (picks.contains(optionIndex)) {
      picks.remove(optionIndex);
      emit(state.copyWith(bonusPicks: picks));
      return;
    }
    if (picks.length >= b.requiredPicks) {
      // Nama+arti: pilihan tunggal per bagian — ketuk opsi lain memindah.
      if (!b.isNameMeaning) return;
      picks.clear();
    }
    picks.add(optionIndex);
    emit(state.copyWith(bonusPicks: picks));
    if (!b.needsSubmit && picks.length == b.requiredPicks) _finishBonus();
  }

  /// Pilih/lepas opsi ARTI surah (bonus nama+arti).
  void pickBonusMeaning(int optionIndex) {
    if (state.bonusStage != BonusStage.running) return;
    if (state.bonus?.isNameMeaning != true) return;
    if (state.bonusMeaningPick == optionIndex) {
      emit(state.copyWith(clearBonusMeaningPick: true));
    } else {
      emit(state.copyWith(bonusMeaningPick: optionIndex));
    }
  }

  /// Konfirmasi jawaban bonus multi-bagian (tombol "Jawab").
  void submitBonus() {
    final b = state.bonus;
    if (b == null || state.bonusStage != BonusStage.running) return;
    if (!state.bonusComplete) return;
    _finishBonus();
  }

  /// Nilai soal bonus: benar → poin PENUH menurut kesulitan ([b.fullPoints]);
  /// nama+arti benar satu bagian → setengahnya; salah / waktu habis → 0. Poin
  /// disisipkan ke [pendingAnswer].
  void _finishBonus({bool timedOut = false}) {
    _bonusTimer?.cancel();
    final b = state.bonus;
    if (b == null || state.bonusStage != BonusStage.running) return;

    // Fraksi kebenaran: 1 = penuh; 0.5 = nama+arti benar satu bagian; 0 = salah.
    double fraction = 0;
    if (!timedOut) {
      if (b.isNameMeaning) {
        final name = b.nameCorrect(
          state.bonusPicks.isNotEmpty ? state.bonusPicks.first : null,
        );
        final meaning = b.meaningCorrect(state.bonusMeaningPick);
        fraction = (name ? 0.5 : 0.0) + (meaning ? 0.5 : 0.0);
      } else if (b.isNumber) {
        fraction =
            b.numberCorrect(
              state.bonusPicks.isNotEmpty ? state.bonusPicks.first : null,
            )
            ? 1
            : 0;
      } else {
        fraction = listEquals(state.bonusPicks, b.correctOptionOrder) ? 1 : 0;
      }
    }

    // Poin PENUH menurut kesulitan bila benar (tidak menyusut mengikuti sisa
    // waktu — santri bebas berpikir tenang). Nama+arti benar sebagian → separuh.
    final points = fraction > 0 ? (b.fullPoints * fraction).round() : 0;
    emit(
      state.copyWith(
        bonusStage: BonusStage.done,
        bonusCorrect: fraction > 0,
        bonusFraction: fraction,
        bonusEarned: points,
        pendingAnswer: state.pendingAnswer?.withBonus(points),
      ),
    );
  }

  /// Lanjut ke soal berikutnya, atau selesaikan sesi bila soal terakhir.
  Future<void> next() async {
    final pending = state.pendingAnswer;
    if (pending == null) return;
    await _commitVoiceAnswer(pending);
  }

  /// Catat [answer] soal suara saat ini lalu lanjut ke soal berikutnya (atau
  /// selesaikan sesi bila soal terakhir). Dipakai tombol "Lanjut" maupun skip
  /// otomatis saat waktu berpikir habis.
  Future<void> _commitVoiceAnswer(QuizAnswer answer) async {
    _voiceTimer?.cancel();
    _retryTimer?.cancel();
    _bonusPrepTimer?.cancel();
    _bonusTimer?.cancel();
    final answers = [...state.answers, answer];
    final q = state.currentQuestion;
    final review = q == null
        ? state.review
        : [...state.review, _voiceReview(q, answer)];

    if (state.isLastQuestion) {
      final result = QuizResult(
        answers: answers,
        questionCount: state.questions.length,
        mode: QuizMode.voice,
      );
      emit(
        state.copyWith(
          status: QuizStatus.finished,
          answers: answers,
          review: review,
          result: result,
          saving: true,
          clearSaveError: true,
        ),
      );
      final save = await repository.saveAttempt(
        mode: QuizMode.voice,
        score: result.leaderboardScore,
        questionScores: result.scores,
        juz: state.settings.sortedJuz,
        bonusTotal: result.totalBonus,
      );
      save.fold(
        ifLeft: (f) =>
            emit(state.copyWith(saving: false, saveError: f.message)),
        ifRight: (_) => emit(state.copyWith(saving: false)),
      );
      // Sesi selesai — layar hasil tak butuh Whisper, lepas lock untuk user lain.
      await _releaseSession();
      return;
    }

    emit(
      state.copyWith(
        answers: answers,
        review: review,
        currentIndex: state.currentIndex + 1,
        phase: AnswerPhase.idle,
        attempt: 1,
        bestPercent: 0,
        passed: false,
        revealAnswer: false,
        bonusPrepSecondsLeft: 0,
        clearCurrentResult: true,
        clearBestResult: true,
        clearPendingAnswer: true,
        // Reset bonus untuk soal berikutnya.
        bonusStage: BonusStage.none,
        bonusSecondsLeft: 0,
        bonusPicks: const [],
        bonusFraction: 0,
        bonusEarned: 0,
        clearBonus: true,
        clearBonusCorrect: true,
        clearBonusMeaningPick: true,
      ),
    );
    // Soal baru → mulai lagi hitung mundur berpikir.
    _startVoiceTimer();
  }

  /// Main lagi dari awal dengan setelan yang sama (soal baru).
  Future<void> playAgain() => start(state.settings);

  /// Ringkasan review satu soal mode PILIHAN (pertanyaan + jawaban + kunci).
  QuizReviewItem _choiceReview(
    QuizQuestion q,
    List<int> picks,
    int? meaningPick,
    bool correct,
    int score,
  ) {
    final t = q.trivia;
    if (t == null) {
      final your = picks
          .where((i) => i >= 0 && i < q.options.length)
          .map((i) => q.options[i].text)
          .join('   ');
      final n = q.answerAyahCount;
      return QuizReviewItem(
        correct: correct,
        score: score,
        question: n > 1
            ? 'Pilih $n ayat lanjutan yang benar'
            : 'Pilih lanjutan ayat yang benar',
        promptArabic: q.prompt.text,
        yourAnswer: your.isEmpty ? '—' : your,
        yourAnswerArabic: true,
        correctAnswer: q.answerAyat.map((a) => a.text).join('   '),
        correctAnswerArabic: true,
      );
    }
    if (t.isNameMeaning) {
      final nameIdx = picks.isNotEmpty ? picks.first : -1;
      final yourName = (nameIdx >= 0 && nameIdx < t.options.length)
          ? t.optionName(nameIdx)
          : '—';
      final yourMeaning =
          (meaningPick != null &&
              meaningPick >= 0 &&
              meaningPick < t.meaningOptions.length)
          ? t.meaningOptions[meaningPick]
          : '—';
      return QuizReviewItem(
        correct: correct,
        score: score,
        question: t.questionTextWith('ayat di atas'),
        promptArabic: q.prompt.text,
        yourAnswer: '$yourName — $yourMeaning',
        correctAnswer: t.answerLabel,
      );
    }
    final idx = picks.isNotEmpty ? picks.first : -1;
    return QuizReviewItem(
      correct: correct,
      score: score,
      question: t.questionTextWith('ayat di atas'),
      promptArabic: q.prompt.text,
      yourAnswer: (idx >= 0 && idx < t.numberOptions.length)
          ? '${t.numberOptions[idx]}'
          : '—',
      correctAnswer: t.answerLabel,
    );
  }

  /// Ringkasan review satu soal mode SUARA (instruksi + akurasi + ayat benar).
  QuizReviewItem _voiceReview(QuizQuestion q, QuizAnswer a) {
    final question = switch (q.task) {
      QuizVoiceTask.lastAyah => 'Baca ayat TERAKHIR surah dari ayat ini',
      QuizVoiceTask.specificAyah =>
        'Baca ayat ke-${q.targetAyahNumber} dari surah ini',
      QuizVoiceTask.continueAyah =>
        q.answerAyahCount > 1
            ? 'Lanjutkan ${q.answerAyahCount} ayat berikutnya'
            : 'Lanjutkan ayat berikutnya',
    };
    return QuizReviewItem(
      correct: a.passed,
      score: a.score,
      question: question,
      promptArabic: q.prompt.text,
      yourAnswer: a.passed
          ? 'Bacaan lolos (${a.score}%)'
          : 'Akurasi ${a.score}%',
      correctAnswer: q.answer.map((e) => e.text).join(' '),
      correctAnswerArabic: true,
    );
  }

  @override
  Future<void> close() async {
    // Keluar (mis. tekan back di tengah kuis) → hentikan timer & lepas lock.
    _choiceTimer?.cancel();
    _choiceBonusTimer?.cancel();
    _choiceBonusIntroTimer?.cancel();
    _feedbackTimer?.cancel();
    _bonusTimer?.cancel();
    _voiceTimer?.cancel();
    _retryTimer?.cancel();
    _bonusPrepTimer?.cancel();
    await _releaseSession();
    await _recorder.dispose();
    return super.close();
  }
}
