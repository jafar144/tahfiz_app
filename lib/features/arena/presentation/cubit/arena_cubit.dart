import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';

/// Cubit shell Tahfiz Arena: memuat profil ringkas user (role + kelas santri),
/// energi untuk top bar, dan status jatah Tantangan harian.
class ArenaCubit extends Cubit<ArenaState> {
  final QuizRepository repository;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  ArenaCubit(this.repository, this.auth, this.firestore)
    : super(const ArenaState());

  /// Energi dilewati untuk admin / saat master switch mati (samakan dengan
  /// perilaku kuis).
  bool get _skipEnergy => !QuizConfig.enforceEnergy || state.role == 'admin';

  Future<void> load() async {
    final user = auth.currentUser;
    if (user == null) {
      emit(
        state.copyWith(
          status: ArenaStatus.error,
          errorMessage: 'Sesi berakhir. Silakan masuk ulang.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ArenaStatus.loading));
    try {
      // Role dari profil users.
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final role = (userDoc.data()?['role'] as String?) ?? '';

      // Kelas hanya relevan untuk santri (dokumen santri_profiles/{uid}).
      String? kelas;
      if (role == 'santri') {
        final santriDoc = await firestore
            .collection('santri_profiles')
            .doc(user.uid)
            .get();
        kelas = (santriDoc.data()?['kelas'] as String?)?.trim();
      }

      emit(state.copyWith(status: ArenaStatus.ready, role: role, kelas: kelas));

      // Energi & status Tantangan dimuat menyusul (top bar menampilkan
      // skeleton sementara).
      await Future.wait([refreshEnergy(), refreshChallengeStatus()]);
    } catch (e) {
      emit(
        state.copyWith(
          status: ArenaStatus.error,
          errorMessage: 'Gagal memuat Tahfiz Arena: $e',
        ),
      );
    }
  }

  /// Muat ulang energi (dipanggil saat kembali dari kuis / pengisian tiba).
  Future<void> refreshEnergy() async {
    if (_skipEnergy) {
      emit(
        state.copyWith(
          energy: const QuizEnergy(current: 10, max: 10),
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

  /// Muat ulang penanda jatah Tantangan harian (untuk label kartu; server
  /// tetap penegak aturannya). Gagal baca → biarkan (kartu tetap aktif).
  Future<void> refreshChallengeStatus() async {
    final uid = auth.currentUser?.uid;
    if (uid == null || !state.canChallenge) return;
    try {
      final doc = await firestore
          .collection('quiz_challenge_days')
          .doc(uid)
          .get();
      final data = doc.data() ?? const {};
      emit(
        state.copyWith(
          voicePlayedDate: (data['voice'] as String?) ?? '',
          choicePlayedDate: (data['choice'] as String?) ?? '',
        ),
      );
    } catch (_) {
      // Rules menutup akses / offline → abaikan; server tetap menegakkan.
    }
  }

  /// Segarkan semuanya saat kembali dari sesi kuis.
  Future<void> refresh() async {
    await Future.wait([refreshEnergy(), refreshChallengeStatus()]);
  }
}
