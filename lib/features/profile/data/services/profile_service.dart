// lib/features/profile/data/services/profile_service.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/features/profile/domain/entities/profile.dart';
import 'package:shsh_social/features/profile/domain/repositories/profile_repository.dart';

class ProfileService {
  final ProfileRepository repository;

  ProfileService(this.repository);

  Future<Either<Failure, Profile>> getProfile(String userId) {
    return repository.getProfile(userId);
  }

  Future<Either<Failure, void>> updateProfile(String userId, Profile profile) {
    return repository.updateProfile(userId, profile);
  }

  Future<Either<Failure, String>> uploadAvatar(String userId, File file) {
    return repository.uploadAvatar(userId, file);
  }

  Future<Either<Failure, void>> deleteAvatar(String userId) {
    return repository.deleteAvatar(userId);
  }

  Future<Either<Failure, void>> updateEmoji(String userId, String emoji) {
    return repository.updateEmoji(userId, emoji);
  }

  Future<Either<Failure, void>> updatePremium(String userId, bool isPremium) {
    return repository.updatePremium(userId, isPremium);
  }
}
