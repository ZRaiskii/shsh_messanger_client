class PhotoModel {
  final String messageId;
  final String timestamp;
  final String photoUrl;
  final String senderId;

  PhotoModel({
    required this.messageId,
    required this.timestamp,
    required this.photoUrl,
    required this.senderId,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      messageId: json['messageId'],
      timestamp: json['timestamp'],
      photoUrl: json['photoUrl'],
      senderId: json['senderId'],
    );
  }
}
