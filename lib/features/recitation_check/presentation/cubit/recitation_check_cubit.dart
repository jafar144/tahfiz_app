import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/repositories/recitation_repository.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/cubit/recitation_check_state.dart';

class RecitationCheckCubit extends Cubit<RecitationCheckState> {
  final RecitationRepository repository;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;

  RecitationCheckCubit(this.repository) : super(const RecitationCheckState());

  /// Muat daftar surah saat halaman dibuka.
  Future<void> init() async {
    if (state.surahs.isNotEmpty) return;
    emit(
      state.copyWith(status: RecitationStatus.loadingSurah, clearError: true),
    );
    final res = await repository.getSurahList();
    await res.fold(
      ifLeft: (f) async => emit(
        state.copyWith(status: RecitationStatus.error, errorMessage: f.message),
      ),
      ifRight: (surahs) async {
        emit(
          state.copyWith(
            status: RecitationStatus.ready,
            surahs: surahs,
            selectedSurah: surahs.isNotEmpty ? surahs.first : null,
            fromAyah: 1,
            toAyah: 1,
            clearResult: true,
          ),
        );
        await _refreshTargetAyat();
      },
    );
  }

  Future<void> selectSurah(SurahInfo surah) async {
    emit(
      state.copyWith(
        selectedSurah: surah,
        fromAyah: 1,
        toAyah: 1,
        clearResult: true,
      ),
    );
    await _refreshTargetAyat();
  }

  Future<void> setFrom(int from) async {
    final to = state.toAyah < from ? from : state.toAyah;
    emit(state.copyWith(fromAyah: from, toAyah: to, clearResult: true));
    await _refreshTargetAyat();
  }

  Future<void> setTo(int to) async {
    final from = state.fromAyah > to ? to : state.fromAyah;
    emit(state.copyWith(toAyah: to, fromAyah: from, clearResult: true));
    await _refreshTargetAyat();
  }

  /// Muat teks ayat target + halaman mushaf agar bisa langsung ditampilkan
  /// sebelum rekam.
  Future<void> _refreshTargetAyat() async {
    final surah = state.selectedSurah;
    if (surah == null) return;
    final targetRes = await repository.getAyatRange(
      surahId: surah.id,
      from: state.fromAyah,
      to: state.toAyah,
    );
    final pageRes = await repository.getPageAyat(
      surahId: surah.id,
      from: state.fromAyah,
      to: state.toAyah,
    );
    emit(
      state.copyWith(
        targetAyat: targetRes.fold(ifLeft: (_) => const [], ifRight: (a) => a),
        pageAyat: pageRes.fold(ifLeft: (_) => const [], ifRight: (a) => a),
      ),
    );
  }

  Future<void> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        emit(
          state.copyWith(
            status: RecitationStatus.error,
            errorMessage: 'Izin mikrofon ditolak. Aktifkan di pengaturan.',
          ),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recordPath = path;
      emit(
        state.copyWith(
          status: RecitationStatus.recording,
          clearResult: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RecitationStatus.error,
          errorMessage: 'Gagal memulai rekaman: $e',
        ),
      );
    }
  }

  /// Hentikan rekaman lalu transkripsi + cocokkan dengan ayat target.
  Future<void> stopAndCheck() async {
    final surah = state.selectedSurah;
    if (surah == null) return;
    try {
      final stopped = await _recorder.stop();
      final filePath = stopped ?? _recordPath;
      if (filePath == null) {
        emit(
          state.copyWith(
            status: RecitationStatus.error,
            errorMessage: 'Rekaman tidak tersimpan.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(status: RecitationStatus.processing, clearError: true),
      );

      var ayat = state.targetAyat;
      if (ayat.isEmpty) {
        final ayatRes = await repository.getAyatRange(
          surahId: surah.id,
          from: state.fromAyah,
          to: state.toAyah,
        );
        ayat = ayatRes.fold<List<Ayah>>(
          ifLeft: (_) => const [],
          ifRight: (a) => a,
        );
      }
      if (ayat.isEmpty) {
        emit(
          state.copyWith(
            status: RecitationStatus.error,
            errorMessage: 'Ayat target tidak ditemukan.',
          ),
        );
        return;
      }

      final res = await repository.checkRecitation(
        targetAyat: ayat,
        audioFilePath: filePath,
        mimeType: 'audio/mp4',
      );
      res.fold(
        ifLeft: (f) => emit(
          state.copyWith(
            status: RecitationStatus.error,
            errorMessage: f.message,
          ),
        ),
        ifRight: (result) => emit(
          state.copyWith(
            status: RecitationStatus.done,
            result: result,
            targetAyat: ayat,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RecitationStatus.error,
          errorMessage: 'Gagal memproses bacaan: $e',
        ),
      );
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    emit(
      state.copyWith(
        status: RecitationStatus.ready,
        clearResult: true,
        clearError: true,
      ),
    );
  }

  void backToReady() {
    emit(
      state.copyWith(
        status: RecitationStatus.ready,
        clearResult: true,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _recorder.dispose();
    return super.close();
  }
}
