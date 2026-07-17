import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/app_config/domain/entities/app_feature.dart';
import 'package:khoirunnasyien/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_state.dart';

class AppConfigCubit extends Cubit<AppConfigState> {
  final AppConfigRepository repository;
  StreamSubscription? _subscription;

  AppConfigCubit(this.repository) : super(AppConfigState());

  void start() {
    if (_subscription != null) return;

    emit(AppConfigState(status: AppConfigStatus.loading, config: state.config));

    _subscription = repository.watch().listen(
      (config) {
        if (isClosed) return;
        emit(
          AppConfigState(
            status: AppConfigStatus.ready,
            config: config,
            updatingFeatures: state.updatingFeatures,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(
          AppConfigState(
            status: AppConfigStatus.failure,
            config: state.config,
            errorMessage: 'Gagal memuat App Config: $error',
          ),
        );
      },
    );
  }

  Future<void> setFeatureEnabled(AppFeature feature, bool enabled) async {
    if (state.isUpdating(feature)) return;

    final previousConfig = state.config;
    final updatingFeatures = {...state.updatingFeatures, feature};
    emit(
      AppConfigState(
        status: AppConfigStatus.ready,
        config: previousConfig.withFeature(feature, enabled),
        updatingFeatures: updatingFeatures,
      ),
    );

    try {
      await repository.setFeatureEnabled(feature, enabled);
      if (isClosed) return;

      emit(
        AppConfigState(
          status: AppConfigStatus.ready,
          config: state.config,
          updatingFeatures: {...state.updatingFeatures}..remove(feature),
        ),
      );
    } catch (error) {
      if (isClosed) return;

      emit(
        AppConfigState(
          status: AppConfigStatus.failure,
          config: previousConfig,
          updatingFeatures: {...state.updatingFeatures}..remove(feature),
          errorMessage: 'Gagal menyimpan App Config: $error',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
