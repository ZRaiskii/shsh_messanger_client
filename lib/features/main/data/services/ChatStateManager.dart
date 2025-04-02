import 'package:flutter/material.dart';

import '../../../chat/domain/entities/message.dart';

class ChatStateManager {
  // Приватный конструктор
  ChatStateManager._privateConstructor();

  // Единственный экземпляр класса
  static final ChatStateManager _instance =
      ChatStateManager._privateConstructor();

  // Метод для доступа к экземпляру
  static ChatStateManager get instance => _instance;

  // Остальные поля и методы
  final Map<String, ValueNotifier<bool>> _typingStatusNotifiers = {};
  final Map<String, ValueNotifier<bool>> _isOnlineMap = {};
  final Map<String, ValueNotifier<String>> _userIdMap = {};
  final Map<String, ValueNotifier<String>> _recipientIdMap = {};
  final Map<String, ValueNotifier<Map<String, dynamic>>> _profileDataMap = {};
  final Map<String, ValueNotifier<Message>> _lastMessageMap = {};
  final Map<String, ValueNotifier<bool>> _isLoadingMap = {};
  final Map<String, ValueNotifier<String>> _errorMap = {};

  ValueNotifier<bool> getTypingStatus(String chatId) {
    if (!_typingStatusNotifiers.containsKey(chatId)) {
      _typingStatusNotifiers[chatId] = ValueNotifier<bool>(false);
    }
    return _typingStatusNotifiers[chatId]!;
  }

  // Обновление статуса печатания
  void updateTypingStatus(String chatId, bool isTyping) {
    final notifier = getTypingStatus(chatId);
    notifier.value = isTyping;
  }

  // Получение или создание ValueNotifier для состояния онлайн
  ValueNotifier<bool> getIsOnline(String chatId) {
    return _isOnlineMap.putIfAbsent(chatId, () => ValueNotifier<bool>(false));
  }

  // Получение или создание ValueNotifier для ID пользователя
  ValueNotifier<String> getUserId(String chatId) {
    return _userIdMap.putIfAbsent(chatId, () => ValueNotifier<String>(''));
  }

  // Получение или создание ValueNotifier для ID получателя
  ValueNotifier<String> getRecipientId(String chatId) {
    return _recipientIdMap.putIfAbsent(chatId, () => ValueNotifier<String>(''));
  }

  // Получение или создание ValueNotifier для данных профиля
  ValueNotifier<Map<String, dynamic>> getProfileData(String chatId) {
    return _profileDataMap.putIfAbsent(
        chatId, () => ValueNotifier<Map<String, dynamic>>({}));
  }

  // Получение или создание ValueNotifier для последнего сообщения
  ValueNotifier<Message> getLastMessage(String chatId) {
    return _lastMessageMap.putIfAbsent(
        chatId,
        () => ValueNotifier<Message>(
              Message(
                id: '', // Убедитесь, что все поля инициализированы
                chatId: chatId,
                senderId: '',
                recipientId: '',
                content: '',
                timestamp: DateTime.now(),
                status: "failed",
              ),
            ));
  }

  // Получение или создание ValueNotifier для состояния загрузки
  ValueNotifier<bool> getIsLoading(String chatId) {
    return _isLoadingMap.putIfAbsent(chatId, () => ValueNotifier<bool>(false));
  }

  // Получение или создание ValueNotifier для ошибок
  ValueNotifier<String> getError(String chatId) {
    return _errorMap.putIfAbsent(chatId, () => ValueNotifier<String>(''));
  }

  // Установка состояния загрузки
  void setIsLoading(String chatId, bool isLoading) {
    getIsLoading(chatId).value = isLoading;
  }

  // Установка ошибки (вывод в консоль)
  void setError(String chatId, String error) {
    debugPrint('Error in chat $chatId: $error'); // Вывод ошибки в консоль
    getError(chatId).value = error;
  }

  // Очистка состояния для конкретного чата
  void disposeNotifier(String chatId) {
    _isOnlineMap[chatId]?.dispose();
    _userIdMap[chatId]?.dispose();
    _recipientIdMap[chatId]?.dispose();
    _profileDataMap[chatId]?.dispose();
    _lastMessageMap[chatId]?.dispose();
    _isLoadingMap[chatId]?.dispose();
    _errorMap[chatId]?.dispose();

    _isOnlineMap.remove(chatId);
    _userIdMap.remove(chatId);
    _recipientIdMap.remove(chatId);
    _profileDataMap.remove(chatId);
    _lastMessageMap.remove(chatId);
    _isLoadingMap.remove(chatId);
    _errorMap.remove(chatId);

    _typingStatusNotifiers[chatId]?.dispose();
    _typingStatusNotifiers.remove(chatId);
  }

  // Очистка всех состояний
  void disposeAll() {
    _isOnlineMap.values.forEach((notifier) => notifier.dispose());
    _userIdMap.values.forEach((notifier) => notifier.dispose());
    _recipientIdMap.values.forEach((notifier) => notifier.dispose());
    _profileDataMap.values.forEach((notifier) => notifier.dispose());
    _lastMessageMap.values.forEach((notifier) => notifier.dispose());
    _isLoadingMap.values.forEach((notifier) => notifier.dispose());
    _errorMap.values.forEach((notifier) => notifier.dispose());

    _isOnlineMap.clear();
    _userIdMap.clear();
    _recipientIdMap.clear();
    _profileDataMap.clear();
    _lastMessageMap.clear();
    _isLoadingMap.clear();
    _errorMap.clear();
  }
}
