// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final String token;
  final String refreshToken;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.token,
    required this.refreshToken,
  });

  @override
  List<Object> get props => [id, email, username, token, refreshToken];
}
