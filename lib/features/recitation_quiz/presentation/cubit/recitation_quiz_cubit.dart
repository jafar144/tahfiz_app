import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';

class RecitationQuizCubit extends Cubit<RecitationQuizState> {
  final QuizRepository repository;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;

  /// Timer perpanjang lock sesi selama bermain; null bila tak bermain.
  Timer? _heartbeat;

  /// True bila sesi ini sedang memegang lock (perlu dilepas saat keluar).
  bool _holdsLock = false;

  /// Jumlah soal per sesi.
  static const int kQuestionCount = 10;

  /// Ambang lolos & nilai penuh.
  static const int kPassThreshold = 80;
  static const int kPerfectThreshold = 90;

  /// Interval perpanjang lock (lebih pendek dari lease server 2 menit).
  static const Duration _heartbeatInterval = Duration(seconds: 40);

  /// Saklar sistem energi. Set `false` saat testing agar energi tidak pernah
  /// dipotong & lock sesi dilewati (kuis bisa dimainkan tanpa batas).
  /// Kembalikan ke `true` untuk produksi.
  static const bool kEnforceEnergy = true;

  RecitationQuizCubit(this.repository) : super(const RecitationQuizState());

  /// Muat energi terkini untuk ditampilkan di layar intro.
  Future<void> loadEnergy() async {
    // Testing: tampilkan energi penuh & jangan panggil server.
    if (!kEnforceEnergy) {
      emit(state.copyWith(
        energy: const QuizEnergy(current: 6, max: 6),
        energyLoading: false,
      ));
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
    // Layar untuk kembali bila gagal mulai (intro, atau result saat "Main Lagi").
    final backStatus = state.status == QuizStatus.finished
        ? QuizStatus.finished
        : QuizStatus.intro;

    emit(state.copyWith(
      status: QuizStatus.loading,
      settings: settings,
      clearStartBlock: true,
    ));

    // Susun soal dulu (lokal, tanpa biaya) sebelum menyentuh lock/energi.
    final res = await repository.generateQuestions(
      count: kQuestionCount,
      settings: settings,
    );

    await res.fold(
      ifLeft: (f) async => emit(state.copyWith(
        status: QuizStatus.error,
        errorMessage: f.message,
      )),
      ifRight: (qs) async {
        // Testing: lewati lock & energi sepenuhnya.
        if (!kEnforceEnergy) {
          _enterPlaying(settings, qs, state.energy);
          return;
        }

        final started = await repository.startSession();
        await started.fold(
          ifLeft: (f) async {
            final reason =
                f is QuizBlockedFailure ? f.reason : QuizBlockReason.unknown;
            if (reason == QuizBlockReason.noEnergy) {
              // Energi habis → segarkan; tombol menonaktif sendiri.
              final refreshed = await repository.getEnergy();
              emit(state.copyWith(
                status: backStatus,
                energy: refreshed.fold(
                  ifLeft: (_) => state.energy,
                  ifRight: (e) => e,
                ),
              ));
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
    emit(RecitationQuizState(
      status: QuizStatus.playing,
      settings: settings,
      energy: energy,
      questions: questions,
      phase: AnswerPhase.idle,
    ));
    _startHeartbeat();
  }

  void _startHeartbeat() {
    if (!kEnforceEnergy) return;
    _holdsLock = true;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => repository.heartbeat());
  }

  /// Lepas lock + hentikan heartbeat (dipanggil saat selesai / keluar).
  Future<void> _releaseSession() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    if (_holdsLock) {
      _holdsLock = false;
      await repository.endSession();
    }
  }

  /// Bersihkan penanda blokir setelah bottom sheet ditampilkan.
  void clearStartBlock() {
    if (state.startBlock != null) emit(state.copyWith(clearStartBlock: true));
  }

  Future<void> startRecording() async {
    if (state.currentQuestion == null) return;
    try {
      if (!await _recorder.hasPermission()) {
        emit(state.copyWith(
          errorMessage: 'Izin mikrofon ditolak. Aktifkan di pengaturan.',
        ));
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
    try {
      final stopped = await _recorder.stop();
      final path = stopped ?? _recordPath;
      if (path == null) {
        emit(state.copyWith(
          phase: AnswerPhase.idle,
          errorMessage: 'Rekaman tidak tersimpan.',
        ));
        return;
      }
      emit(state.copyWith(phase: AnswerPhase.processing, clearError: true));

      final res = await repository.checkAnswer(
        answerAyat: q.answer,
        audioFilePath: path,
        mimeType: 'audio/mp4',
      );
      res.fold(
        ifLeft: (f) => emit(state.copyWith(
          phase: AnswerPhase.idle,
          errorMessage: f.message,
        )),
        ifRight: _applyResult,
      );
    } catch (e) {
      emit(state.copyWith(
        phase: AnswerPhase.idle,
        errorMessage: 'Gagal memproses bacaan: $e',
      ));
    }
  }

  void _applyResult(RecitationResult result) {
    final pct = result.accuracyPercent;
    final best = pct > state.bestPercent ? pct : state.bestPercent;
    final bestResult = pct >= state.bestPercent ? result : state.bestResult;

    // Gagal (<80%) di percobaan 1 → beri kesempatan ulang, belum difinalisasi.
    if (pct < kPassThreshold && state.attempt == 1) {
      emit(state.copyWith(
        phase: AnswerPhase.revealed,
        currentResult: result,
        bestPercent: best,
        bestResult: bestResult,
        passed: false,
        revealAnswer: false,
      ));
      return;
    }

    // Finalisasi: lolos, atau gagal 2x.
    final bool passed = pct >= kPassThreshold;
    final bool reveal = !passed; // gagal 2x → buka kunci
    final int score = passed
        ? (pct > kPerfectThreshold ? 100 : pct)
        : best; // gagal 2x → persentase terbaik dari 2 percobaan

    final pending = QuizAnswer(
      questionIndex: state.currentIndex,
      score: score,
      attempts: state.attempt,
      passed: passed,
      bestResult: passed ? result : bestResult,
    );

    emit(state.copyWith(
      phase: AnswerPhase.revealed,
      currentResult: result,
      bestPercent: best,
      bestResult: bestResult,
      passed: passed,
      revealAnswer: reveal,
      pendingAnswer: pending,
    ));
  }

  /// Ulangi soal (percobaan ke-2).
  void retry() {
    emit(state.copyWith(
      phase: AnswerPhase.idle,
      attempt: 2,
      passed: false,
      revealAnswer: false,
      clearCurrentResult: true,
    ));
  }

  /// Lanjut ke soal berikutnya, atau selesaikan sesi bila soal terakhir.
  Future<void> next() async {
    final pending = state.pendingAnswer;
    if (pending == null) return;
    final answers = [...state.answers, pending];

    if (state.isLastQuestion) {
      final result = QuizResult(
        answers: answers,
        questionCount: state.questions.length,
      );
      emit(state.copyWith(
        status: QuizStatus.finished,
        answers: answers,
        result: result,
        saving: true,
        clearSaveError: true,
      ));
      final save = await repository.saveAttempt(
        totalScore: result.totalScore,
        questionScores: result.scores,
        juz: state.settings.sortedJuz,
        crossSurah: state.settings.crossSurah,
      );
      save.fold(
        ifLeft: (f) => emit(state.copyWith(saving: false, saveError: f.message)),
        ifRight: (_) => emit(state.copyWith(saving: false)),
      );
      // Sesi selesai — layar hasil tak butuh Whisper, lepas lock untuk user lain.
      await _releaseSession();
      return;
    }

    emit(state.copyWith(
      answers: answers,
      currentIndex: state.currentIndex + 1,
      phase: AnswerPhase.idle,
      attempt: 1,
      bestPercent: 0,
      passed: false,
      revealAnswer: false,
      clearCurrentResult: true,
      clearBestResult: true,
      clearPendingAnswer: true,
    ));
  }

  /// Main lagi dari awal dengan setelan yang sama (soal baru).
  Future<void> playAgain() => start(state.settings);

  @override
  Future<void> close() async {
    // Keluar (mis. tekan back di tengah kuis) → lepas lock sesi.
    await _releaseSession();
    await _recorder.dispose();
    return super.close();
  }
}
