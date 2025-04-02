// lib/features/profile/domain/usecases/update_premium_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/profile/domain/repositories/profile_repository.dart';

class UpdatePremiumParams extends Equatable {
  final String userId;
  final bool isPremium;

  const UpdatePremiumParams({required this.userId, required this.isPremium});

  @override
  List<Object> get props => [userId, isPremium];
}

class UpdatePremiumUseCase implements UseCase<void, UpdatePremiumParams> {
  final ProfileRepository repository;

  UpdatePremiumUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePremiumParams params) async {
    return await repository.updatePremium(params.userId, params.isPremium);
  }
}
