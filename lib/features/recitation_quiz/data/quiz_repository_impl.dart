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
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
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

  /// Koleksi papan juara bulanan (best-score, ringan untuk dibaca):
  /// `quiz_leaderboards/{yyyy-MM}/{mode}/{uid}` — satu dokumen per user per
  /// bulan per mode, hanya menyimpan skor TERBAIK. Dipisah per mode karena
  /// skala skor suara & pilihan berbeda dan tak bisa dibandingkan.
  static const String _leaderboardCollection = 'quiz_leaderboards';

  /// Jumlah peringkat yang ditampilkan.
  static const int _leaderboardLimit = 10;

  static String _monthKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  /// Sub-koleksi entri leaderboard untuk [monthKey] + [mode].
  CollectionReference<Map<String, dynamic>> _entriesRef(
    String monthKey,
    QuizMode mode,
  ) =>
      firestore
          .collection(_leaderboardCollection)
          .doc(monthKey)
          .collection(mode.key);

  /// Panjang jawaban maksimum (ayat) per soal.
  static const int _maxAnswerLen = 3;

  /// Jumlah opsi pada mode pilihan ganda.
  static const int _choiceOptionCount = 6;

  @override
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count = 10,
    required QuizSettings settings,
  }) async {
    try {
      final juzList =
          settings.sortedJuz.where(QuizJuz.isSupported).toList();
      if (juzList.isEmpty) {
        return const Left(UnknownFailure('Pilih minimal satu juz.'));
      }

      // Susun pool ayat sesuai rentang target tiap juz (surah awal terpilih →
      // surah terakhir juz yang dikunci), urut mushaf. Tiap juz jadi satu
      // "segmen" kontigu; indeks akhir tiap segmen dicatat agar lanjutan tak
      // pernah menyeberang celah antar-segmen (mis. juz 29 & 30 tak berurutan).
      final pool = <Ayah>[];
      final segmentEnds = <int>{};
      for (final j in juzList) {
        final seg = await local.getAyatForSurahRange(
          fromSurah: settings.startSurahFor(j),
          toSurah: QuizJuz.lastSurah(j),
        );
        if (seg.isEmpty) continue;
        pool.addAll(seg);
        segmentEnds.add(pool.length - 1);
      }
      if (pool.length < 2) {
        return const Left(UnknownFailure('Rentang target terpilih terlalu pendek.'));
      }

      // Basmalah (dari Al-Fatihah 1:1) untuk transisi antar surah.
      final basmalahList = await local.getAyatRange(surahId: 1, from: 1, to: 1);
      final basmalahText =
          basmalahList.isNotEmpty ? basmalahList.first.text : '';

      // Kandidat prompt = indeks ayat yang punya minimal 1 ayat lanjutan valid
      // (bukan ayat penutup segmen — lanjutannya akan menyeberang celah).
      final candidates = <int>[];
      for (var i = 0; i < pool.length - 1; i++) {
        if (segmentEnds.contains(i)) continue;
        candidates.add(i);
      }
      if (candidates.isEmpty) {
        return const Left(
            UnknownFailure('Data tidak cukup untuk menyusun soal.'));
      }

      final rng = Random();
      candidates.shuffle(rng);
      final chosen = candidates.take(min(count, candidates.length));

      final isChoice = settings.mode.isChoice;
      final questions = <QuizQuestion>[];
      for (final i in chosen) {
        final prompt = pool[i];
        final maxLen = _availableAnswerLen(pool, i, segmentEnds);
        final len = 1 + rng.nextInt(maxLen); // 1.._maxAnswerLen (dibatasi)

        // Ayat lanjutan mentah (tanpa basmalah).
        final rawAnswer = [for (var k = 1; k <= len; k++) pool[i + k]];

        if (isChoice) {
          // Mode pilihan: jawaban = ayat asli tanpa basmalah + rakit opsi.
          questions.add(QuizQuestion(
            prompt: prompt,
            answer: rawAnswer,
            options: _buildOptions(pool, prompt, rawAnswer, rng),
          ));
        } else {
          // Mode suara: sisipkan basmalah di depan ayat awal surah baru.
          final answer = <Ayah>[];
          for (final a in rawAnswer) {
            if (a.number == 1 && basmalahText.isNotEmpty) {
              answer.add(Ayah(
                surahId: a.surahId,
                number: 0, // penanda basmalah (bukan ayat bernomor)
                text: basmalahText,
                page: a.page,
                surahName: a.surahName,
              ));
            }
            answer.add(a);
          }
          questions.add(QuizQuestion(prompt: prompt, answer: answer));
        }
      }

      questions.shuffle(rng);
      return Right(questions);
    } catch (e) {
      return Left(UnknownFailure('Gagal menyusun soal kuis: $e'));
    }
  }

  /// Rakit [_choiceOptionCount] opsi ayat: jawaban benar + distraktor teracak.
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
    final distractorPool = pool
        .where((a) => a.number != 0 && !used.any((u) => sameAyah(u, a)))
        .toList()
      ..shuffle(rng);

    final options = <Ayah>[...answer];
    for (final a in distractorPool) {
      if (options.length >= _choiceOptionCount) break;
      if (options.any((o) => sameAyah(o, a))) continue;
      options.add(a);
    }

    options.shuffle(rng);
    return options;
  }

  /// Jumlah ayat lanjutan yang tersedia dari indeks [i] (1.._maxAnswerLen).
  /// Berhenti di batas segmen (indeks penutup di [segmentEnds]) agar lanjutan
  /// tak menyeberang celah antar rentang juz.
  int _availableAnswerLen(List<Ayah> pool, int i, Set<int> segmentEnds) {
    var len = 0;
    for (var k = 1; k <= _maxAnswerLen; k++) {
      final idx = i + k;
      if (idx >= pool.length) break;
      if (segmentEnds.contains(idx - 1)) break; // pool[idx] mulai segmen baru
      len++;
    }
    return len; // >= 1 karena i selalu diambil dari kandidat valid
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
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        return const Left(UnknownFailure('Sesi berakhir. Masuk ulang.'));
      }

      var name = user.displayName ?? '';
      var role = '';
      try {
        final doc =
            await firestore.collection('users').doc(user.uid).get();
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

      // 1) HISTORI — selalu ditulis (arsip lengkap tiap sesi).
      await firestore.collection(_collection).add({
        'user_id': user.uid,
        'user_name': name,
        'role': role,
        'mode': mode.key,
        'juz': juz,
        'score': score,
        'bonus_score': bonusTotal,
        'question_scores': questionScores,
        'question_count': questionScores.length,
        'date_key': dateKey,
        'created_at': FieldValue.serverTimestamp(),
      });

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
        );
      } catch (_) {
        // Diabaikan; skor tetap tersimpan di histori.
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan hasil kuis: $e'));
    }
  }

  /// Tulis best-score ke `quiz_leaderboards/{bulan}/{mode}/{uid}` hanya bila
  /// [score] melebihi best-score yang sudah tercatat (bulan + mode ini).
  Future<void> _upsertLeaderboardEntry({
    required String uid,
    required String name,
    required String role,
    required QuizMode mode,
    required String monthKey,
    required int score,
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
    QuizMode mode,
  ) async {
    try {
      final monthKey = _monthKey(DateTime.now());
      final entriesRef = _entriesRef(monthKey, mode);

      final snap = await entriesRef
          .orderBy('best_score', descending: true)
          .limit(_leaderboardLimit)
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
          if (myData != null) {
            myEntry = _entryFromDoc(myData);
            // Peringkat = 1 + jumlah user dengan skor lebih tinggi
            // (aggregate count — tidak membaca isi dokumen).
            try {
              final agg = await entriesRef
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

      return Right(MonthlyLeaderboard(
        mode: mode,
        monthKey: monthKey,
        entries: entries,
        myEntry: myEntry,
        myRank: myRank,
      ));
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
  Future<Either<Failure, QuizEnergy>> startSession() async {
    try {
      return Right(await energyRemote.startSession());
    } on FirebaseFunctionsException catch (e) {
      return Left(QuizBlockedFailure(
        _reasonOf(e),
        e.message ?? 'Kuis sedang tidak bisa dimulai.',
      ));
    } catch (e) {
      return Left(QuizBlockedFailure(
        QuizBlockReason.unknown,
        'Gagal memulai sesi: $e',
      ));
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
