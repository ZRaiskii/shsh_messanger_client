import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../chat/data/services/stomp_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final AuthRepository authRepository;
  final WebSocketClientService webSocketClientService;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.authRepository,
    required this.webSocketClientService,
  }) : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      final failureOrUser = await loginUseCase(event.params);
      await failureOrUser.fold(
        (failure) async {
          emit(AuthFailure(failure.message));
        },
        (user) async {
          await authRepository.cacheUser(user);
          await webSocketClientService.setUserIdAndConnect(user.id);
          emit(AuthSuccess(user));
        },
      );
    });

    on<RegisterEvent>((event, emit) async {
      emit(AuthLoading());
      final failureOrUser = await registerUseCase(event.params);
      await failureOrUser.fold(
        (failure) async {
          emit(AuthFailure(failure.message));
        },
        (user) async {
          emit(const AuthFailure("Регистрация успешна!"));
        },
      );
    });
  }
}
