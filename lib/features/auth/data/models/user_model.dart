// lib/features/auth/data/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String username;
  final String token;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.token,
    required this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'token': token,
      'refreshToken': refreshToken,
    };
  }
}
