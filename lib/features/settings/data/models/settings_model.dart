// lib/features/settings/data/models/settings_model.dart
class SettingsModel {
  final String language;
  final bool notificationsEnabled;
  final bool snowflakesEnabled;
  final double messageTextSize;
  final String wallpaper;
  final String chatListType;

  SettingsModel({
    required this.language,
    required this.notificationsEnabled,
    required this.snowflakesEnabled,
    required this.messageTextSize,
    required this.wallpaper,
    required this.chatListType,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      language: json['language'] ?? 'English',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      snowflakesEnabled: json['snowflakesEnabled'] ?? true,
      messageTextSize: json['messageTextSize'] ?? 16.0,
      wallpaper: json['wallpaper'] ?? 'default',
      chatListType: json['chatListType'] ?? 'two_line',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'snowflakesEnabled': snowflakesEnabled,
      'messageTextSize': messageTextSize,
      'wallpaper': wallpaper,
      'chatListType': chatListType,
    };
  }
}
