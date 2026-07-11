import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dart_either/dart_either.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/data/quran_local_datasource.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_energy_remote_datasource.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_block.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_bonus.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_knowledge_bank.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuranLocalDataSource local;
  final RecitationRepository recitation;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final QuizEnergyRemoteDataSource energyRemote;

  QuizRepositoryImpl({
    required this.local,
    required this.recitation,
    required this.firestore,
    required this.auth,
    required this.energyRemote,
  });

  /// Koleksi HISTORI seluruh sesi (arsip; bisa dipakai analitik kapan saja).
  static const String _collection = 'recitation_quiz_attempts';

  /// Total XP Arena/Journey disimpan bersama progres Surah Journey.
  static const String _journeyProgressCollection = 'surah_journey_progress';

  /// Koleksi papan juara bulanan (best-score, ringan untuk dibaca):
  /// `quiz_leaderboards/{yyyy-MM}/{mode}/{uid}` — satu dokumen per user per
  /// bulan per mode, hanya menyimpan skor TERBAIK. Dipisah per mode karena
  /// skala skor suara & pilihan berbeda dan tak bisa dibandingkan.
  static const String _leaderboardCollection = 'quiz_leaderboards';

  static String _monthKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  /// Sub-koleksi entri leaderboard untuk [monthKey] + [mode].
  CollectionReference<Map<String, dynamic>> _entriesRef(
    String monthKey,
    QuizMode mode,
  ) => firestore
      .collection(_leaderboardCollection)
      .doc(monthKey)
      .collection(mode.key);

  @override
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count = 10,
    required QuizSettings settings,
  }) async {
    try {
      final juzList = settings.sortedJuz.where(QuizJuz.isSupported).toList();
      if (juzList.isEmpty && settings.extraSurahs.isEmpty) {
        return const Left(UnknownFailure('Pilih minimal satu juz.'));
      }

      // Susun pool ayat sesuai rentang target tiap juz (surah awal terpilih →
      // surah terakhir juz yang dikunci), urut mushaf. Tiap juz jadi satu
      // "segmen" kontigu; indeks akhir tiap segmen dicatat agar lanjutan tak
      // pernah menyeberang celah antar-segmen (mis. juz 29 & 30 tak berurutan).
      final pool = <Ayah>[];
      final segmentEnds = <int>{};
      for (final j in juzList) {
        final before = pool.length;
        if (QuizJuz.hasAyahSegments(j)) {
          // Juz "rentang ayat" (batas di tengah surah): rangkai tiap segmen.
          for (final s in QuizJuz.ayahSegments(j)) {
            pool.addAll(
              await local.getAyatRange(surahId: s.$1, from: s.$2, to: s.$3),
            );
          }
        } else {
          // Juz "surah utuh": dari surah awal terpilih s.d. surah terakhir juz.
          pool.addAll(
            await local.getAyatForSurahRange(
              fromSurah: settings.startSurahFor(j),
              toSurah: QuizJuz.lastSurah(j),
            ),
          );
        }
        // Tiap juz = satu segmen kontigu; lanjutan tak boleh menyeberang celah
        // antar-juz.
        if (pool.length > before) segmentEnds.add(pool.length - 1);
      }

      // Surah tambahan di luar juz terpilih (paket Tantangan yang tak
      // berurutan, mis. Pra Takhossus Awal). Surah yang BERURUTAN mushaf
      // dirangkai jadi satu segmen (sambungan antar surah tetap jalan);
      // lompatan antar kelompok menjadi batas segmen baru.
      final poolSurahs = pool.map((a) => a.surahId).toSet();
      final extras = settings.sortedExtraSurahs
          .where((s) => !poolSurahs.contains(s))
          .toList();
      for (var i = 0; i < extras.length;) {
        var end = i;
        while (end + 1 < extras.length && extras[end + 1] == extras[end] + 1) {
          end++;
        }
        final before = pool.length;
        pool.addAll(
          await local.getAyatForSurahRange(
            fromSurah: extras[i],
            toSurah: extras[end],
          ),
        );
        if (pool.length > before) segmentEnds.add(pool.length - 1);
        i = end + 1;
      }

      if (pool.length < 2) {
        return const Left(
          UnknownFailure('Rentang target terpilih terlalu pendek.'),
        );
      }

      // Basmalah (dari Al-Fatihah 1:1) untuk transisi antar surah.
      final basmalahList = await local.getAyatRange(surahId: 1, from: 1, to: 1);
      final basmalahText = basmalahList.isNotEmpty
          ? basmalahList.first.text
          : '';

      // Peta bantu per surah — dipakai soal "ayat terakhir" & "ayat ke-N".
      final ayatBySurah = <int, Map<int, Ayah>>{};
      final lastAyahOf = <int, Ayah>{};
      for (final a in pool) {
        (ayatBySurah[a.surahId] ??= <int, Ayah>{})[a.number] = a;
        final last = lastAyahOf[a.surahId];
        if (last == null || a.number > last.number) lastAyahOf[a.surahId] = a;
      }

      // Surah yang UTUH dalam pool (ayat 1..terakhir-asli lengkap) → boleh dipakai
      // untuk tugas "ayat terakhir surah" & "ayat ke-N". Surah terpotong (mis.
      // Al-Baqarah pada juz 1-3) hanya untuk tugas "lanjutkan ayat".
      final surahTotals = <int, int>{
        for (final s in await local.getSurahList()) s.id: s.totalVerses,
      };
      final completeSurahs = <int>{
        for (final e in ayatBySurah.entries)
          if (surahTotals[e.key] != null &&
              e.value.containsKey(1) &&
              e.value.length == surahTotals[e.key])
            e.key,
      };

      // Himpunan surah dalam pool (distraktor soal trivia / tebak surah).
      final allowedSurahs = pool.map((a) => a.surahId).toSet();

      // Kandidat prompt = indeks ayat yang punya minimal 1 ayat lanjutan valid
      // (bukan ayat penutup segmen — lanjutannya akan menyeberang celah).
      final candidates = <int>[];
      for (var i = 0; i < pool.length - 1; i++) {
        if (segmentEnds.contains(i)) continue;
        candidates.add(i);
      }
      if (candidates.isEmpty) {
        return const Left(
          UnknownFailure('Data tidak cukup untuk menyusun soal.'),
        );
      }

      final rng = Random();
      candidates.shuffle(rng);

      // Mode PILIHAN: urutan soal TETAP — tiap kelipatan interval diisi soal
      // trivia/bonus, selebihnya soal lanjutan ayat. Tak diacak ulang agar
      // posisi kelipatan konsisten.
      if (settings.mode.isChoice) {
        final choiceQuestions = _buildChoiceQuestions(
          pool: pool,
          candidates: candidates,
          segmentEnds: segmentEnds,
          allowed: allowedSurahs,
          count: count,
          includeKnowledge: !settings.ayatOnly,
          rng: rng,
        );
        if (choiceQuestions.isEmpty) {
          return const Left(
            UnknownFailure('Data tidak cukup untuk menyusun soal.'),
          );
        }
        return Right(choiceQuestions);
      }

      // Mode SUARA: undi tugas per soal; urutan diacak di akhir.
      final questions = <QuizQuestion>[];

      // Penjaga keragaman: prompt tak boleh kembar (soal "ayat ke-N" memindah
      // prompt ke ayat penutup surah — bisa bentrok), dan tiap variasi tugas
      // per surah hanya muncul sekali per sesi.
      final usedPrompts = <String>{};
      final usedVariants = <String>{};
      String keyOf(Ayah a) => '${a.surahId}:${a.number}';

      for (final i in candidates) {
        if (questions.length >= count) break;
        final prompt = pool[i];

        // Undi tugas soal (lanjutkan / ayat terakhir / ayat ke-N).
        final task = _rollVoiceTask(
          prompt,
          lastAyahOf,
          completeSurahs,
          usedVariants,
          rng,
        );
        switch (task) {
          case QuizVoiceTask.continueAyah:
            if (!usedPrompts.add(keyOf(prompt))) continue;
            // Jumlah ayat jawaban menyesuaikan PANJANG ayat (pendek → banyak,
            // panjang → 1).
            final len = _voiceAnswerLen(pool, i, segmentEnds, rng);
            final rawAnswer = [for (var k = 1; k <= len; k++) pool[i + k]];
            questions.add(
              QuizQuestion(
                prompt: prompt,
                answer: _withBasmalah(rawAnswer, basmalahText),
              ),
            );

          case QuizVoiceTask.lastAyah:
            // Ayat tampil dijamin bukan penutup surah (dicek saat undi tugas).
            if (!usedPrompts.add(keyOf(prompt))) continue;
            usedVariants.add('last:${prompt.surahId}');
            questions.add(
              QuizQuestion(
                task: QuizVoiceTask.lastAyah,
                prompt: prompt,
                answer: [lastAyahOf[prompt.surahId]!],
              ),
            );

          case QuizVoiceTask.specificAyah:
            // Prompt DIGANTI jadi ayat penutup surah; minta baca ayat ke-N
            // (N = 1..min(5, jumlah ayat), tak pernah ayat penutup itu sendiri).
            final s = prompt.surahId;
            final closing = lastAyahOf[s]!;
            var maxN = min(QuizConfig.specificAyahMaxNumber, closing.number);
            if (maxN >= closing.number) maxN = closing.number - 1;
            if (maxN < 1) continue;
            final n = 1 + rng.nextInt(maxN);
            final target = ayatBySurah[s]?[n];
            if (target == null) continue;
            if (!usedPrompts.add(keyOf(closing))) continue;
            usedVariants.add('specific:$s');
            questions.add(
              QuizQuestion(
                task: QuizVoiceTask.specificAyah,
                prompt: closing,
                answer: _withBasmalah([target], basmalahText),
              ),
            );
        }
      }

      if (questions.isEmpty) {
        return const Left(
          UnknownFailure('Data tidak cukup untuk menyusun soal.'),
        );
      }

      questions.shuffle(rng);
      return Right(questions);
    } catch (e) {
      return Left(UnknownFailure('Gagal menyusun soal kuis: $e'));
    }
  }

  /// Susun soal mode PILIHAN dengan urutan TETAP: posisi kelipatan
  /// [QuizConfig.choiceTriviaInterval] (5, 10, …) diisi soal TRIVIA surah
  /// dengan tipe yang dirotasi merata (nama+arti / jumlah ayat / urutan);
  /// selebihnya soal lanjutan ayat pilihan ganda.
  List<QuizQuestion> _buildChoiceQuestions({
    required List<Ayah> pool,
    required List<int> candidates,
    required Set<int> segmentEnds,
    required Set<int> allowed,
    required int count,
    required bool includeKnowledge,
    required Random rng,
  }) {
    final questions = <QuizQuestion>[];
    final usedPrompts = <String>{};
    String keyOf(Ayah a) => '${a.surahId}:${a.number}';

    // Rotasi tipe trivia agar 3 variasi muncul merata sepanjang sesi.
    final triviaTypes = <QuizBonusType>[
      QuizBonusType.nameMeaning,
      QuizBonusType.ayahCount,
      QuizBonusType.orderNumber,
    ]..shuffle(rng);
    var triviaCount = 0;

    var cursor = 0; // penunjuk kandidat berikutnya untuk soal biasa

    // Kandidat (indeks pool) belum-terpakai berikutnya untuk soal lanjutan ayat.
    int? nextNormal() {
      while (cursor < candidates.length &&
          usedPrompts.contains(keyOf(pool[candidates[cursor]]))) {
        cursor++;
      }
      if (cursor >= candidates.length) return null;
      return candidates[cursor++];
    }

    while (questions.length < count) {
      final pos = questions.length + 1; // posisi 1-based soal berikutnya
      final wantTrivia = pos % QuizConfig.choiceTriviaInterval == 0;

      if (wantTrivia) {
        if (includeKnowledge && rng.nextBool()) {
          final match = QuizKnowledgeBank.vocabularyMatch(
            allowedSurahs: allowed,
            rng: rng,
          );
          if (match != null) {
            questions.add(
              QuizQuestion(
                prompt: pool[candidates[cursor % candidates.length]],
                answer: const [],
                vocabMatch: match,
              ),
            );
            continue;
          }
        }
        final type = triviaTypes[triviaCount % triviaTypes.length];
        QuizQuestion? built;
        // Cari surah (dari kandidat mana pun yang belum terpakai) yang bisa
        // menyusun tipe trivia terjadwal.
        for (var s = cursor; s < candidates.length; s++) {
          final a = pool[candidates[s]];
          if (usedPrompts.contains(keyOf(a))) continue;
          final trivia = QuizBonusQuestion.generateTrivia(
            surah: a.surahId,
            allowed: allowed,
            rng: rng,
            type: type,
          );
          if (trivia != null) {
            usedPrompts.add(keyOf(a));
            built = QuizQuestion(prompt: a, answer: const [], trivia: trivia);
            break;
          }
        }
        if (built != null) {
          questions.add(built);
          triviaCount++;
          continue;
        }
        // Tak ada surah cocok untuk tipe ini → isi posisi dgn soal biasa.
      }

      // Soal biasa (lanjutan ayat).
      final i = nextNormal();
      if (i == null) break; // kandidat habis
      final prompt = pool[i];
      usedPrompts.add(keyOf(prompt));
      if (includeKnowledge && questions.length % 4 == 2) {
        final knowledge = QuizKnowledgeBank.vocabularyMeaning(
          allowedSurahs: allowed,
          ayat: pool,
          rng: rng,
        );
        if (knowledge != null) {
          questions.add(
            QuizQuestion(
              prompt: prompt,
              answer: const [],
              knowledge: knowledge,
            ),
          );
          continue;
        }
      }
      final maxLen = _availableAnswerLen(pool, i, segmentEnds);
      final len = 1 + rng.nextInt(maxLen); // 1..maxAnswerAyah (dibatasi)
      final rawAnswer = [for (var k = 1; k <= len; k++) pool[i + k]];
      questions.add(
        QuizQuestion(
          prompt: prompt,
          answer: rawAnswer,
          options: _buildOptions(pool, prompt, rawAnswer, rng),
        ),
      );
    }
    return questions;
  }

  /// Undi tugas soal suara untuk [prompt] sesuai bobot [QuizConfig]; hanya
  /// tugas yang valid untuk ayat/surah ini yang ikut diundi.
  QuizVoiceTask _rollVoiceTask(
    Ayah prompt,
    Map<int, Ayah> lastAyahOf,
    Set<int> completeSurahs,
    Set<String> usedVariants,
    Random rng,
  ) {
    final s = prompt.surahId;
    final last = lastAyahOf[s];
    // Variasi "ayat terakhir/ke-N" HANYA untuk surah UTUH dalam pool (surah
    // terpotong pada juz 1-3 tak boleh mereferensi ayat di luar rentang).
    final whole = completeSurahs.contains(s);
    final entries = <(QuizVoiceTask, int)>[
      (QuizVoiceTask.continueAyah, QuizConfig.voiceTaskWeightContinue),
    ];
    // "Ayat terakhir surah": ayat tampil tak boleh penutup surah itu sendiri.
    if (whole &&
        last != null &&
        prompt.number != last.number &&
        !usedVariants.contains('last:$s')) {
      entries.add((QuizVoiceTask.lastAyah, QuizConfig.voiceTaskWeightLastAyah));
    }
    // "Baca ayat ke-N": butuh minimal 2 ayat agar N ≠ ayat penutup.
    if (whole &&
        last != null &&
        last.number >= 2 &&
        !usedVariants.contains('specific:$s')) {
      entries.add((
        QuizVoiceTask.specificAyah,
        QuizConfig.voiceTaskWeightSpecificAyah,
      ));
    }
    var roll = rng.nextInt(entries.fold(0, (t, e) => t + e.$2));
    for (final e in entries) {
      roll -= e.$2;
      if (roll < 0) return e.$1;
    }
    return QuizVoiceTask.continueAyah;
  }

  /// Sisipkan penanda basmalah (ayat bernomor 0) di depan tiap ayat pertama
  /// surah — bacaan yang dimulai dari awal surah memang diawali basmalah.
  List<Ayah> _withBasmalah(List<Ayah> rawAnswer, String basmalahText) {
    if (basmalahText.isEmpty) return rawAnswer;
    final answer = <Ayah>[];
    for (final a in rawAnswer) {
      if (a.number == 1) {
        answer.add(
          Ayah(
            surahId: a.surahId,
            number: 0, // penanda basmalah (bukan ayat bernomor)
            text: basmalahText,
            page: a.page,
            surahName: a.surahName,
          ),
        );
      }
      answer.add(a);
    }
    return answer;
  }

  /// Rakit [QuizConfig.choiceOptionCount] opsi ayat: jawaban benar + distraktor.
  /// Distraktor diambil dari [pool] (selain prompt & ayat jawaban), unik per
  /// (surah, nomor). Semua diacak agar posisi jawaban tak tertebak.
  List<Ayah> _buildOptions(
    List<Ayah> pool,
    Ayah prompt,
    List<Ayah> answer,
    Random rng,
  ) {
    bool sameAyah(Ayah a, Ayah b) =>
        a.surahId == b.surahId && a.number == b.number;

    final used = [prompt, ...answer];
    final distractorPool =
        pool
            .where((a) => a.number != 0 && !used.any((u) => sameAyah(u, a)))
            .toList()
          ..shuffle(rng);

    final options = <Ayah>[...answer];
    for (final a in distractorPool) {
      if (options.length >= QuizConfig.choiceOptionCount) break;
      if (options.any((o) => sameAyah(o, a))) continue;
      options.add(a);
    }

    options.shuffle(rng);
    return options;
  }

  /// Jumlah ayat lanjutan yang tersedia dari indeks [i] (1..[maxCap]).
  /// Berhenti di batas segmen (indeks penutup di [segmentEnds]) agar lanjutan
  /// tak menyeberang celah antar rentang juz.
  int _availableAnswerLen(
    List<Ayah> pool,
    int i,
    Set<int> segmentEnds, {
    int maxCap = QuizConfig.maxAnswerAyah,
  }) {
    var len = 0;
    for (var k = 1; k <= maxCap; k++) {
      final idx = i + k;
      if (idx >= pool.length) break;
      if (segmentEnds.contains(idx - 1)) break; // pool[idx] mulai segmen baru
      len++;
    }
    return len; // >= 1 karena i selalu diambil dari kandidat valid
  }

  /// Perkiraan jumlah kata sebuah ayat (untuk mengklasifikasi panjang ayat).
  int _wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Jumlah ayat jawaban mode SUARA menurut PANJANG ayat pertama jawaban:
  /// pendek → lebih banyak (3-4), sedang → 2-3, panjang → 1. Diundi dalam range
  /// kategori lalu dibatasi ketersediaan ayat (tak menyeberang batas juz).
  int _voiceAnswerLen(
    List<Ayah> pool,
    int i,
    Set<int> segmentEnds,
    Random rng,
  ) {
    final available = _availableAnswerLen(
      pool,
      i,
      segmentEnds,
      maxCap: QuizConfig.voiceMaxAnswerAyah,
    );
    if (available <= 1) return available; // kandidat selalu punya ≥ 1 lanjutan

    final words = _wordCount(pool[i + 1].text);
    final range = words <= QuizConfig.voiceShortAyahMaxWords
        ? QuizConfig.voiceShortRange
        : words <= QuizConfig.voiceMediumAyahMaxWords
        ? QuizConfig.voiceMediumRange
        : QuizConfig.voiceLongRange;
    final target = range.$1 + rng.nextInt(range.$2 - range.$1 + 1);
    final len = target < available ? target : available;
    return len < 1 ? 1 : len;
  }

  @override
  Future<Either<Failure, RecitationResult>> checkAnswer({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  }) {
    return recitation.checkRecitation(
      targetAyat: answerAyat,
      audioFilePath: audioFilePath,
      mimeType: mimeType,
    );
  }

  @override
  Future<Either<Failure, void>> saveAttempt({
    required QuizMode mode,
    required int score,
    required List<int> questionScores,
    required List<int> juz,
    int bonusTotal = 0,
    int earnedXp = 0,
    String? kelas,
    String? scopeKelas,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }

      var name = user.displayName ?? '';
      var role = '';
      try {
        final doc = await firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        final data = doc.data();
        if (data != null) {
          name = (data['name'] as String?)?.trim().isNotEmpty == true
              ? data['name'] as String
              : name;
          role = (data['role'] as String?) ?? '';
        }
      } catch (_) {
        // Nama/role opsional; simpan tetap lanjut walau gagal ambil profil.
      }

      // Admin & asatidz hanya menguji kuis — hasil TIDAK disimpan (baik histori
      // maupun leaderboard). Hanya santri yang tercatat.
      if (role == 'admin' || role == 'asatidz') {
        return const Right(null);
      }

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final dateKey = '${now.year}-${two(now.month)}-${two(now.day)}';

      // 1) HISTORI — selalu ditulis (arsip lengkap tiap sesi). Saat OFFLINE,
      // Firestore mengantre tulisan ini di cache lokal & menyinkronkannya
      // otomatis saat online — jadi bila menunggu ACK server melewati batas
      // waktu, anggap tersimpan (data TIDAK hilang) daripada menggantung UI.
      try {
        await firestore
            .collection(_collection)
            .add({
              'user_id': user.uid,
              'user_name': name,
              'role': role,
              'mode': mode.key,
              'juz': juz,
              'score': score,
              'bonus_score': bonusTotal,
              'earned_xp': earnedXp,
              'question_scores': questionScores,
              'question_count': questionScores.length,
              'date_key': dateKey,
              // Penanda Tantangan (challenge) + kelas terkait; null = latihan
              // lama (data sebelum fitur Arena).
              'kind': 'challenge',
              'kelas': ?kelas,
              'scope_kelas': ?scopeKelas,
              'created_at': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 6));
      } on TimeoutException {
        // Tersimpan di antrean lokal & akan tersinkron otomatis; lanjut.
      }

      // 2) LEADERBOARD — hanya diperbarui bila skor melampaui best (best-effort;
      // histori di atas adalah sumber kebenaran, kegagalan di sini diabaikan).
      try {
        await _upsertLeaderboardEntry(
          uid: user.uid,
          name: name,
          role: role,
          mode: mode,
          monthKey: _monthKey(now),
          score: score,
          kelas: kelas,
        ).timeout(const Duration(seconds: 6));
      } catch (_) {
        // Diabaikan (termasuk offline: transaksi butuh server); skor tetap
        // tersimpan di histori sebagai sumber kebenaran.
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan hasil kuis: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> awardXp(int amount) async {
    if (amount <= 0) return const Right(null);
    try {
      final user = auth.currentUser;
      if (user == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }

      try {
        await firestore
            .collection(_journeyProgressCollection)
            .doc(user.uid)
            .set({
              'xp': FieldValue.increment(amount),
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 6));
      } on TimeoutException {
        // Tersimpan di antrean lokal & akan tersinkron otomatis saat online.
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menambahkan XP kuis: $e'));
    }
  }

  /// Tulis best-score ke `quiz_leaderboards/{bulan}/{mode}/{uid}` hanya bila
  /// [score] melebihi best-score yang sudah tercatat (bulan + mode ini).
  /// [kelas] = kelas leaderboard santri (papan juara difilter per kelas).
  Future<void> _upsertLeaderboardEntry({
    required String uid,
    required String name,
    required String role,
    required QuizMode mode,
    required String monthKey,
    required int score,
    String? kelas,
  }) {
    final ref = _entriesRef(monthKey, mode).doc(uid);
    return firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final prevBest = (snap.data()?['best_score'] as num?)?.toInt() ?? -1;

      final data = <String, dynamic>{
        'user_id': uid,
        'user_name': name,
        'role': role,
        'month_key': monthKey,
        'mode': mode.key,
        'kelas': ?kelas,
        'last_score': score,
        'play_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (score > prevBest) {
        data['best_score'] = score;
        // Tie-break: skor sama → yang lebih dulu mencapainya menang.
        data['best_at'] = FieldValue.serverTimestamp();
      }
      tx.set(ref, data, SetOptions(merge: true));
    });
  }

  @override
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = auth.currentUser;
      if (user == null) return false;
      final doc = await firestore.collection('users').doc(user.uid).get();
      return (doc.data()?['role'] as String?) == 'admin';
    } catch (_) {
      // Gagal baca profil → anggap non-admin agar energi tetap membatasi.
      return false;
    }
  }

  @override
  Future<Either<Failure, MonthlyLeaderboard>> getMonthlyLeaderboard(
    QuizMode mode, {
    String? kelas,
  }) async {
    try {
      final monthKey = _monthKey(DateTime.now());
      final entriesRef = _entriesRef(monthKey, mode);

      // Papan per kelas (Tantangan): saring entri milik kelas terkait.
      Query<Map<String, dynamic>> query = entriesRef;
      if (kelas != null) query = query.where('kelas', isEqualTo: kelas);

      final snap = await query
          .orderBy('best_score', descending: true)
          .limit(QuizConfig.leaderboardLimit)
          .get();

      final entries = snap.docs.map((d) => _entryFromDoc(d.data())).toList()
        // Tie-break di sisi klien: skor sama → best_at lebih awal di atas.
        ..sort((a, b) {
          final byScore = b.bestScore.compareTo(a.bestScore);
          if (byScore != 0) return byScore;
          final aAt = a.bestAt, bAt = b.bestAt;
          if (aAt == null) return 1;
          if (bAt == null) return -1;
          return aAt.compareTo(bAt);
        });

      // Posisi user saat ini (bila sudah pernah main bulan ini).
      LeaderboardEntry? myEntry;
      int? myRank;
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final idx = entries.indexWhere((e) => e.userId == uid);
        if (idx >= 0) {
          myEntry = entries[idx];
          myRank = idx + 1;
        } else {
          final mySnap = await entriesRef.doc(uid).get();
          final myData = mySnap.data();
          // Pada papan per kelas, entri user hanya relevan bila kelasnya sama
          // (mis. admin membuka papan kelas lain → tanpa kartu "Kamu").
          if (myData != null && (kelas == null || myData['kelas'] == kelas)) {
            myEntry = _entryFromDoc(myData);
            // Peringkat = 1 + jumlah user dengan skor lebih tinggi
            // (aggregate count — tidak membaca isi dokumen).
            try {
              final agg = await query
                  .where('best_score', isGreaterThan: myEntry.bestScore)
                  .count()
                  .get();
              myRank = (agg.count ?? 0) + 1;
            } catch (_) {
              myRank = null; // Peringkat opsional; kartu tetap tampil.
            }
          }
        }
      }

      return Right(
        MonthlyLeaderboard(
          mode: mode,
          monthKey: monthKey,
          entries: entries,
          myEntry: myEntry,
          myRank: myRank,
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Gagal memuat leaderboard: $e'));
    }
  }

  LeaderboardEntry _entryFromDoc(Map<String, dynamic> data) {
    return LeaderboardEntry(
      userId: (data['user_id'] as String?) ?? '',
      name: ((data['user_name'] as String?)?.trim().isNotEmpty ?? false)
          ? (data['user_name'] as String).trim()
          : 'Tanpa Nama',
      role: (data['role'] as String?) ?? '',
      bestScore: (data['best_score'] as num?)?.toInt() ?? 0,
      bestAt: (data['best_at'] as Timestamp?)?.toDate(),
      playCount: (data['play_count'] as num?)?.toInt() ?? 0,
    );
  }

  // Energi dihitung SISI SERVER (Cloud Function) memakai waktu server, sehingga
  // tidak bisa diakali dengan mengubah jam perangkat. Repo hanya mendelegasikan.

  @override
  Future<Either<Failure, QuizEnergy>> getEnergy() async {
    try {
      return Right(await energyRemote.getEnergy());
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat energi.'));
    } catch (e) {
      return Left(ServerFailure('Gagal memuat energi: $e'));
    }
  }

  @override
  Future<Either<Failure, QuizEnergy>> startSession({
    required QuizMode mode,
    bool challenge = false,
  }) async {
    try {
      return Right(
        await energyRemote.startSession(mode: mode, challenge: challenge),
      );
    } on FirebaseFunctionsException catch (e) {
      return Left(
        QuizBlockedFailure(
          _reasonOf(e),
          e.message ?? 'Kuis sedang tidak bisa dimulai.',
        ),
      );
    } catch (e) {
      return Left(
        QuizBlockedFailure(QuizBlockReason.unknown, 'Gagal memulai sesi: $e'),
      );
    }
  }

  @override
  Future<void> heartbeat() => energyRemote.heartbeat();

  @override
  Future<void> endSession() => energyRemote.endSession();

  /// Petakan error callable → alasan blokir yang dipahami UI.
  QuizBlockReason _reasonOf(FirebaseFunctionsException e) {
    final details = e.details;
    final reason = details is Map ? details['reason'] : null;
    switch (reason) {
      case 'busy':
        return QuizBlockReason.busy;
      case 'whisper':
        return QuizBlockReason.whisperLimit;
      case 'no_energy':
        return QuizBlockReason.noEnergy;
      // 'daily_limit' = nama lama (kompatibilitas saat fase deploy).
      case 'challenge_limit':
      case 'daily_limit':
        return QuizBlockReason.challengeLimit;
    }
    // Fallback berdasarkan kode HttpsError bila details tak ada.
    switch (e.code) {
      case 'resource-exhausted':
        return QuizBlockReason.whisperLimit;
      case 'aborted':
        return QuizBlockReason.busy;
      case 'failed-precondition':
        return QuizBlockReason.noEnergy;
    }
    return QuizBlockReason.unknown;
  }
}
