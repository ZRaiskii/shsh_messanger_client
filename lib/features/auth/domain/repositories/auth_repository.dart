// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:shsh_social/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> register(String email, String username, String password);
  Future<User> login(String email, String password);
  Future<User> refreshToken(String refreshToken);
  Future<User> getUser();
  Future<void> cacheUser(User userToCache);
}
