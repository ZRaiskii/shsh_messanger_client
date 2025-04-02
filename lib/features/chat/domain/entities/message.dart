import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String recipientId; // Новое поле
  String content;
  final DateTime timestamp;
  final String? parentMessageId;
  late bool? isEdited;
  final DateTime? editedAt;
  final String status; // Новое поле: SENT, DELIVERED, READ
  final DateTime? deliveredAt; // Новое поле
  final DateTime? readAt; // Новое поле

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    this.parentMessageId,
    this.isEdited = false,
    this.editedAt,
    this.status = 'SENT', // По умолчанию SENT
    this.deliveredAt,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        recipientId,
        content,
        timestamp,
        parentMessageId,
        isEdited,
        editedAt,
        status,
        deliveredAt,
        readAt,
      ];

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['messageId'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      parentMessageId: json['parentMessageId'] ?? '',
      isEdited: json['isEdited'] == 1,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      status: json['status'] ?? 'SENT',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': id,
      'chatId': chatId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'parentMessageId': parentMessageId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'status': status,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? recipientId,
    String? content,
    DateTime? timestamp,
    String? parentMessageId,
    bool? isEdited,
    DateTime? editedAt,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
