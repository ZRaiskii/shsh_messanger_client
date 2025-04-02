// lib/features/auth/data/services/auth_service.dart
import 'package:shsh_social/features/auth/domain/entities/user.dart';
import 'package:shsh_social/features/auth/domain/repositories/auth_repository.dart';

class AuthService {
  final AuthRepository repository;

  AuthService(this.repository);

  Future<User> register(String email, String username, String password) {
    return repository.register(email, username, password);
  }

  Future<User> login(String email, String password) {
    return repository.login(email, password);
  }

  Future<User> refreshToken(String refreshToken) {
    return repository.refreshToken(refreshToken);
  }

  Future<User> getUser() {
    return repository.getUser();
  }

  Future<void> cacheUser(User userToCache) {
    return repository.cacheUser(userToCache);
  }
}
