import 'package:flutter/foundation.dart';

import 'features/chat/data/services/notification_service.dart';
import 'features/chat/data/services/stomp_client.dart';
import 'features/chat/domain/entities/message.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  String? currentChatId;
  bool? isInternet = false;
  bool? isRefresh = true;
  bool? isInit = true;
  Function(Message)? onMessageReceived;
  Function(Message)? onMessageReceivedChats;
  Function(String chatId, String messageId)? removeMessageFromChat;
  Function(String chatId, String readerId, List<String> messageIds)?
      messagesReadNotification;
  Function(String chatId, String readerId, List<String> messageIds)?
      temporaryMessagesReadNotification;
  Function(String messageId, String newContent, String editedAt)?
      updateMessageContent;
  WebSocketClientService? webSocketClientService;
  NotificationService? notificationService;

  // Хранилище сообщений по chatId
  final Map<String, List<Message>> _messagesByChatId = {};

  // ValueNotifier для хранения статуса печатания
  final ValueNotifier<Map<String, Map<String, bool>>> typingStatusNotifier =
      ValueNotifier({});

  factory AppState() {
    return _instance;
  }

  AppState._internal();

  // Метод для получения сообщений по chatId
  List<Message>? getMessagesByChatId(String chatId) {
    return _messagesByChatId[chatId];
  }

  // Метод для обновления статуса печатания
  void updateTypingStatus(String chatId, String userId, bool isTyping) {
    final currentStatus = typingStatusNotifier.value;
    if (!currentStatus.containsKey(chatId)) {
      currentStatus[chatId] = {};
    }
    currentStatus[chatId]![userId] = !isTyping;

    typingStatusNotifier.value = {...currentStatus};
  }

  bool isUserTyping(String chatId, String userId) {
    return typingStatusNotifier.value[chatId]?[userId] ?? false;
  }
}
