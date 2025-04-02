// lib/features/profile/domain/usecases/delete_avatar_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/profile/domain/repositories/profile_repository.dart';

class DeleteAvatarParams extends Equatable {
  final String userId;

  const DeleteAvatarParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

class DeleteAvatarUseCase implements UseCase<void, DeleteAvatarParams> {
  final ProfileRepository repository;

  DeleteAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAvatarParams params) async {
    return await repository.deleteAvatar(params.userId);
  }
}
