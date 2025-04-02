// lib/features/auth/domain/usecases/password_recovery_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/auth/domain/repositories/auth_repository.dart';

class PasswordRecoveryParams extends Equatable {
  final String email;

  const PasswordRecoveryParams({
    required this.email,
  });

  @override
  List<Object> get props => [email];
}

class PasswordRecoveryUseCase implements UseCase<void, PasswordRecoveryParams> {
  final AuthRepository repository;

  PasswordRecoveryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PasswordRecoveryParams params) async {
    try {
      // Здесь должна быть логика восстановления пароля
      // Например, отправка письма на email с инструкциями по восстановлению пароля
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
