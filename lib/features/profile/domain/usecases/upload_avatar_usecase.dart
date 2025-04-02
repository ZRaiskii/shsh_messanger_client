// lib/features/profile/domain/usecases/upload_avatar_usecase.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/profile/domain/repositories/profile_repository.dart';

class UploadAvatarParams extends Equatable {
  final String userId;
  final File file;

  const UploadAvatarParams({required this.userId, required this.file});

  @override
  List<Object> get props => [userId, file];
}

class UploadAvatarUseCase implements UseCase<String, UploadAvatarParams> {
  final ProfileRepository repository;

  UploadAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadAvatarParams params) async {
    return await repository.uploadAvatar(params.userId, params.file);
  }
}
