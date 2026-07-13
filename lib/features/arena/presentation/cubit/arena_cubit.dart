import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_session_rules.dart';
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
  bool get _skipEnergy =>
      !QuizSessionRules.enforceServerGate || state.role == 'admin';

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

      // Energi (termasuk kuota Tantangan mingguan) dimuat menyusul — top bar
      // menampilkan skeleton sementara.
      await refreshEnergy();
    } catch (e) {
      emit(
        state.copyWith(
          status: ArenaStatus.error,
          errorMessage: 'Gagal memuat Tahfiz Arena: $e',
        ),
      );
    }
  }

  /// Muat ulang energi + kuota Tantangan mingguan (dipanggil saat kembali
  /// dari kuis / waktu reset tiba).
  Future<void> refreshEnergy() async {
    if (_skipEnergy) {
      emit(
        state.copyWith(
          energy: const QuizEnergy(
            current: 15,
            max: 15,
            challengeVoiceLeft: 2,
            challengeVoiceMax: 2,
            challengeChoiceLeft: 2,
            challengeChoiceMax: 2,
          ),
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

  /// Segarkan semuanya saat kembali dari sesi kuis.
  Future<void> refresh() => refreshEnergy();
}
