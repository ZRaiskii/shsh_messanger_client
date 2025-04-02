class LastMessage {
  final String content;
  final DateTime timestamp;
  final String senderId; // Добавьте это поле
  final String status; // Добавьте это поле

  LastMessage({
    required this.content,
    required this.timestamp,
    required this.senderId, // Добавьте это поле
    required this.status, // Добавьте это поле
  });

  // Добавьте метод toJson, если его нет
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'status': status,
    };
  }

  // Добавьте метод fromJson, если его нет
  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'] ?? "",
      status: json['status'] ?? "failed",
    );
  }
}
