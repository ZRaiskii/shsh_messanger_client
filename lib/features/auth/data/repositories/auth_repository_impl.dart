// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:shsh_social/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:shsh_social/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shsh_social/features/auth/domain/entities/user.dart';
import 'package:shsh_social/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> register(String email, String username, String password) async {
    final userModel =
        await remoteDataSource.register(email, username, password);
    return User(
      id: userModel.id,
      email: userModel.email,
      username: userModel.username,
      token: userModel.token,
      refreshToken: userModel.refreshToken,
    );
  }

  @override
  Future<User> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);
    print('UM: ${userModel.id}');
    await localDataSource.cacheUser(userModel);
    return User(
      id: userModel.id,
      email: userModel.email,
      username: userModel.username,
      token: userModel.token,
      refreshToken: userModel.refreshToken,
    );
  }

  @override
  Future<User> refreshToken(String refreshToken) async {
    final userModel = await remoteDataSource.refreshToken(refreshToken);
    return User(
      id: userModel.id,
      email: userModel.email,
      username: userModel.username,
      token: userModel.token,
      refreshToken: userModel.refreshToken,
    );
  }

  @override
  Future<User> getUser() async {
    final userModel = await localDataSource.getUser();
    return User(
      id: userModel.id,
      email: userModel.email,
      username: userModel.username,
      token: userModel.token,
      refreshToken: userModel.refreshToken,
    );
  }

  @override
  Future<void> cacheUser(User userToCache) async {
    // print('Caching user: $userToCache');

    // final userModel = UserModel(
    //   id: '', // Если у вас нет id в User, можно оставить пустым или добавить в User
    //   email: userToCache.email,
    //   username: userToCache.username,
    //   token: userToCache.token,
    //   refreshToken: userToCache.refreshToken,
    // );

    // print('UserModel created: $userModel');

    // try {
    //   await localDataSource.cacheUser(userModel);
    //   print('User cached successfully');
    // } catch (e, stacktrace) {
    //   print('Exception occurred while caching user: $e');
    //   print('Stacktrace: $stacktrace');
    //   rethrow;
    // }
  }
}
