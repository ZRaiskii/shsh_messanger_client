// lib/features/auth/domain/usecases/register_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/auth/domain/entities/user.dart';
import 'package:shsh_social/features/auth/domain/repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String email;
  final String username;
  final String password;
  final String confirmPassword;

  const RegisterParams({
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [email, username, password, confirmPassword];
}

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    if (params.password != params.confirmPassword) {
      return Left(ServerFailure('Password and Confirm Password do not match'));
    }

    try {
      final user = await repository.register(
          params.email, params.username, params.password);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
