import 'package:equatable/equatable.dart';

import '../../../chat/domain/entities/message.dart';

class Chat extends Equatable {
  final String id;
  final String user1Id;
  final String user2Id;
  final String createdAt;
  final String username;
  final String email;
  final String descriptionOfProfile;
  final String status;
  Message? lastMessage;
  int notRead;
  int lastSequence;

  Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.username,
    required this.email,
    required this.descriptionOfProfile,
    required this.status,
    required this.notRead,
    required this.lastSequence, // <--- Обязательный параметр
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      createdAt: json['createdAt'],
      username: json['username'] ?? "",
      email: json['email'] ?? "",
      descriptionOfProfile: json['descriptionOfProfile'] ?? "",
      status: json['status'] ?? "",
      notRead: json['notRead'] ?? 0,
      lastSequence: json['lastSequence'] ?? 0, // <--- Парсинг из JSON
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
      'notRead': notRead,
      'lastSequence': lastSequence, // <--- Добавлено в JSON
    };
  }

  Chat copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? createdAt,
    String? username,
    String? email,
    String? descriptionOfProfile,
    String? status,
    Message? lastMessage,
    int? notRead,
    int? lastSequence, // <--- Добавлено в copyWith
  }) {
    return Chat(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      email: email ?? this.email,
      descriptionOfProfile: descriptionOfProfile ?? this.descriptionOfProfile,
      status: status ?? this.status,
      notRead: notRead ?? this.notRead,
      lastSequence: lastSequence ?? this.lastSequence, // <--- Копирование
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        user1Id,
        user2Id,
        createdAt,
        username,
        email,
        descriptionOfProfile,
        status,
        notRead,
        lastSequence, // <--- Добавлено в Equatable props
      ];
}
