import '../../domain/entities/chat.dart';

class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String createdAt;
  final String username;
  final String email;
  final String descriptionOfProfile;
  final String status;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.username,
    required this.email,
    required this.descriptionOfProfile,
    required this.status,
  });

  factory ChatModel.fromJson2(Map<String, dynamic> json) {
    return ChatModel(
      id: json['chatId'] ?? '',
      user1Id: json['user1Id'] ?? '',
      user2Id: json['id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      descriptionOfProfile: json['descriptionOfProfile'] ?? '',
      status: json['status'] ?? '',
    );
  }
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      user1Id: json['user1Id'] ?? '',
      user2Id: json['user2Id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      descriptionOfProfile: json['descriptionOfProfile'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt,
      'username': username,
      'email': email,
      'descriptionOfProfile': descriptionOfProfile,
      'status': status,
    };
  }

  factory ChatModel.fromChat(Chat chat) {
    return ChatModel(
      id: chat.id,
      user1Id: chat.user1Id,
      user2Id: chat.user2Id,
      createdAt: chat.createdAt,
      username: '', // Значение по умолчанию
      email: '', // Значение по умолчанию
      descriptionOfProfile: '', // Значение по умолчанию
      status: '', // Значение по умолчанию
    );
  }
}
