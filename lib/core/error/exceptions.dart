// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Произошла ошибка сервера.']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Произошла ошибка кэша.']);

  @override
  String toString() => 'CacheException: $message';
}
