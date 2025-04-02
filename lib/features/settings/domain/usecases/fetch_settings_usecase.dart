// lib/features/settings/domain/usecases/fetch_settings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/settings/domain/entities/settings.dart';
import 'package:shsh_social/features/settings/domain/repositories/settings_repository.dart';

class FetchSettingsUseCase implements UseCase<Settings, NoParams> {
  final SettingsRepository repository;

  FetchSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, Settings>> call(NoParams params) async {
    try {
      final settings = await repository.fetchSettings();
      return Right(settings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
