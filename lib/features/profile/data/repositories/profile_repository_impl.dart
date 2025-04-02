import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final remoteProfile = await remoteDataSource.getProfile(userId);
      await localDataSource.cacheProfile(remoteProfile);
      return Right(Profile(
        id: remoteProfile.id,
        username: remoteProfile.username,
        email: remoteProfile.email,
        dateOfBirth: remoteProfile.dateOfBirth,
        descriptionOfProfile: remoteProfile.descriptionOfProfile,
        registrationDate: remoteProfile.registrationDate,
        lastUpdated: remoteProfile.lastUpdated,
        gender: remoteProfile.gender,
        avatarUrl: remoteProfile.avatarUrl,
        chatWallpaperUrl: remoteProfile.chatWallpaperUrl,
        premiumExpiresAt: remoteProfile.premiumExpiresAt,
        nicknameEmoji: remoteProfile.nicknameEmoji,
        active: remoteProfile.active,
        premium: remoteProfile.premium,
        shshDeveloper: remoteProfile.shshDeveloper,
        isVerifiedEmail: remoteProfile.isVerifiedEmail,
      ));
    } on ServerException {
      try {
        final localProfile = await localDataSource.getCachedProfile();
        return Right(Profile(
          id: localProfile.id,
          username: localProfile.username,
          email: localProfile.email,
          dateOfBirth: localProfile.dateOfBirth,
          descriptionOfProfile: localProfile.descriptionOfProfile,
          registrationDate: localProfile.registrationDate,
          lastUpdated: localProfile.lastUpdated,
          gender: localProfile.gender,
          avatarUrl: localProfile.avatarUrl,
          chatWallpaperUrl: localProfile.chatWallpaperUrl,
          premiumExpiresAt: localProfile.premiumExpiresAt,
          nicknameEmoji: localProfile.nicknameEmoji,
          active: localProfile.active,
          premium: localProfile.premium,
          shshDeveloper: localProfile.shshDeveloper,
          isVerifiedEmail: localProfile.isVerifiedEmail,
        ));
      } on CacheException {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(
      String userId, Profile profile) async {
    final profileModel = ProfileModel(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      dateOfBirth: profile.dateOfBirth,
      descriptionOfProfile: profile.descriptionOfProfile,
      registrationDate: profile.registrationDate,
      lastUpdated: profile.lastUpdated,
      gender: profile.gender,
      avatarUrl: profile.avatarUrl,
      chatWallpaperUrl: profile.chatWallpaperUrl,
      premiumExpiresAt: profile.premiumExpiresAt,
      nicknameEmoji: profile.nicknameEmoji,
      active: profile.active,
      premium: profile.premium,
      shshDeveloper: profile.shshDeveloper,
      isVerifiedEmail: profile.isVerifiedEmail,
    );
    try {
      await remoteDataSource.updateProfile(userId, profileModel);
      await localDataSource.cacheProfile(profileModel);
      return Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(String userId, File file) async {
    try {
      final message = await remoteDataSource.uploadAvatar(userId, file);
      return Right(message);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvatar(String userId) async {
    try {
      await remoteDataSource.deleteAvatar(userId);
      return Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEmoji(String userId, String emoji) async {
    try {
      await remoteDataSource.updateEmoji(userId, emoji);
      return Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePremium(
      String userId, bool isPremium) async {
    try {
      await remoteDataSource.updatePremium(userId, isPremium);
      return Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
