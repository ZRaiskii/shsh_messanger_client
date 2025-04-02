// lib/features/settings/presentation/bloc/settings_event.dart
part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class FetchSettingsEvent extends SettingsEvent {
  const FetchSettingsEvent();
}

class UpdateSettingsEvent extends SettingsEvent {
  final UpdateSettingsParams params;

  const UpdateSettingsEvent(this.params);

  @override
  List<Object> get props => [params];
}
