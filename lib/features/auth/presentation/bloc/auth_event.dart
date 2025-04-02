// lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final LoginParams params;

  const LoginEvent(this.params);

  @override
  List<Object> get props => [params];
}

class RegisterEvent extends AuthEvent {
  final RegisterParams params;

  const RegisterEvent(this.params);

  @override
  List<Object> get props => [params];
}
