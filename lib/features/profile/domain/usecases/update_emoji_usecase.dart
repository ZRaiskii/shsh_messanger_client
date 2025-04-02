// lib/features/profile/domain/usecases/update_emoji_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/profile/domain/repositories/profile_repository.dart';

class UpdateEmojiParams extends Equatable {
  final String userId;
  final String emoji;

  const UpdateEmojiParams({required this.userId, required this.emoji});

  @override
  List<Object> get props => [userId, emoji];
}

class UpdateEmojiUseCase implements UseCase<void, UpdateEmojiParams> {
  final ProfileRepository repository;

  UpdateEmojiUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateEmojiParams params) async {
    return await repository.updateEmoji(params.userId, params.emoji);
  }
}
