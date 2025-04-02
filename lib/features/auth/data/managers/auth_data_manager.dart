// lib/features/auth/data/managers/auth_data_manager.dart
import 'package:shsh_social/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:shsh_social/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shsh_social/features/auth/data/models/user_model.dart';

class AuthDataManager {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthDataManager({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  Future<UserModel> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        email,
        username,
        password,
      );
      await _localDataSource.cacheUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(email, password);
      await _localDataSource.cacheUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> refreshToken(String refreshToken) async {
    try {
      final user = await _remoteDataSource.refreshToken(refreshToken);
      await _localDataSource.cacheUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getCachedUser() async {
    return await _localDataSource.getUser();
  }
}
