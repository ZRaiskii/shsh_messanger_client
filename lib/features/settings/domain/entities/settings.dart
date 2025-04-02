// lib/features/settings/domain/entities/settings.dart
import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final String language;
  final bool notificationsEnabled;
  final bool snowflakesEnabled;
  final double messageTextSize;
  final String wallpaper;
  final String chatListType;

  const Settings({
    required this.language,
    required this.notificationsEnabled,
    required this.snowflakesEnabled,
    required this.messageTextSize,
    required this.wallpaper,
    required this.chatListType,
  });

  @override
  List<Object> get props => [
        language,
        notificationsEnabled,
        snowflakesEnabled,
        messageTextSize,
        wallpaper,
        chatListType
      ];

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
