// lib/features/settings/presentation/bloc/settings_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/settings/domain/entities/settings.dart';
import 'package:shsh_social/features/settings/domain/usecases/fetch_settings_usecase.dart';
import 'package:shsh_social/features/settings/domain/usecases/update_settings_usecase.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FetchSettingsUseCase fetchSettingsUseCase;
  final UpdateSettingsUseCase updateSettingsUseCase;

  SettingsBloc({
    required this.fetchSettingsUseCase,
    required this.updateSettingsUseCase,
  }) : super(SettingsInitial()) {
    on<FetchSettingsEvent>((event, emit) async {
      emit(SettingsLoading());
      final failureOrSettings = await fetchSettingsUseCase(NoParams());
      failureOrSettings.fold(
        (failure) {
          emit(SettingsFailure(failure.message));
        },
        (settings) {
          emit(SettingsSuccess(settings));
        },
      );
    });

    on<UpdateSettingsEvent>((event, emit) async {
      emit(SettingsLoading());
      final failureOrVoid = await updateSettingsUseCase(event.params);
      failureOrVoid.fold(
        (failure) {
          emit(SettingsFailure(failure.message));
        },
        (_) {
          emit(SettingsSuccess(event.params.settings));
        },
      );
    });
  }
}
