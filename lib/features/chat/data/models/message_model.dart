class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime timestamp;
  final String? parentMessageId;
  final bool isEdited;
  final DateTime? editedAt;
  final String status; // Новое поле: SENT, DELIVERED, READ
  final DateTime? deliveredAt; // Новое поле
  final DateTime? readAt; // Новое поле

  MessageModel({
    required this.messageId,
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

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? ''),
      parentMessageId: json['parentMessageId'] ?? '',
      isEdited: json['edited'] ?? false,
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
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'parentMessageId': parentMessageId,
      'edited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'status': status,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}
