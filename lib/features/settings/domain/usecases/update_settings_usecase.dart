// lib/features/settings/domain/usecases/update_settings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/settings/domain/entities/settings.dart';
import 'package:shsh_social/features/settings/domain/repositories/settings_repository.dart';

class UpdateSettingsParams extends Equatable {
  final Settings settings;

  const UpdateSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}

class UpdateSettingsUseCase implements UseCase<void, UpdateSettingsParams> {
  final SettingsRepository repository;

  UpdateSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateSettingsParams params) async {
    try {
      await repository.updateSettings(params.settings);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
