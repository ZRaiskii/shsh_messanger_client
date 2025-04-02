// lib/features/profile/domain/repositories/profile_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile(String userId);
  Future<Either<Failure, void>> updateProfile(String userId, Profile profile);
  Future<Either<Failure, String>> uploadAvatar(String userId, File file);
  Future<Either<Failure, void>> deleteAvatar(String userId);
  Future<Either<Failure, void>> updateEmoji(String userId, String emoji);
  Future<Either<Failure, void>> updatePremium(String userId, bool isPremium);
}
