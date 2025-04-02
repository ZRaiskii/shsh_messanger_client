// lib/features/profile/domain/usecases/update_profile_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/profile/domain/entities/profile.dart';
import 'package:shsh_social/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileParams extends Equatable {
  final String userId;
  final Profile profile;

  const UpdateProfileParams({required this.userId, required this.profile});

  @override
  List<Object> get props => [userId, profile];
}

class UpdateProfileUseCase implements UseCase<void, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateProfileParams params) async {
    try {
      await repository.updateProfile(params.userId, params.profile);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
