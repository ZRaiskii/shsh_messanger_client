import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';

class ChatStateManager {
  // Приватный конструктор
  ChatStateManager._privateConstructor();

  // Единственный экземпляр класса
  static final ChatStateManager _instance =
      ChatStateManager._privateConstructor();

  // Метод для доступа к экземпляру
  static ChatStateManager get instance => _instance;

  final ValueNotifier<String> isSelectedDelay = ValueNotifier<String>("");

  // ValueNotifier для списка сообщений
  final ValueNotifier<List<Message>> messagesNotifier =
      ValueNotifier<List<Message>>([]);

  final ValueNotifier<List<String>> selectedMessages =
      ValueNotifier<List<String>>([]);

  // ValueNotifier для результатов поиска
  final ValueNotifier<List<Message>> searchResultsNotifier =
      ValueNotifier<List<Message>>([]);

  // ValueNotifier для статуса онлайн/офлайн
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(false);

  // ValueNotifier для последнего времени активности
  final ValueNotifier<String> formattedLastSeenNotifier =
      ValueNotifier<String>('');

  // ValueNotifier для выбранных сообщений (например, для удаления)
  final ValueNotifier<List<String>> selectedMessagesNotifier =
      ValueNotifier<List<String>>([]);

  // ValueNotifier для сообщения, на которое отвечают
  final ValueNotifier<Message?> replyMessageNotifier =
      ValueNotifier<Message?>(null);

  // ValueNotifier для сообщения, которое пересылают
  final ValueNotifier<Message?> forwardMessageNotifier =
      ValueNotifier<Message?>(null);

  // ValueNotifier для данных профиля
  final ValueNotifier<Map<String, dynamic>> profileNotifier =
      ValueNotifier<Map<String, dynamic>>({});

  // ValueNotifier для флага поиска
  final ValueNotifier<bool> isSearchingNotifier = ValueNotifier<bool>(false);

  // ValueNotifier для флага показа поля ввода сообщения
  final ValueNotifier<bool> showMessageInputNotifier =
      ValueNotifier<bool>(true);

  // ValueNotifier для флага загрузки сообщений
  final ValueNotifier<bool> isLoadingMessagesNotifier =
      ValueNotifier<bool>(false);

  // ValueNotifier для флага видимости оверлея профиля
  final ValueNotifier<bool> isProfileOverlayVisibleNotifier =
      ValueNotifier<bool>(false);

  // ValueNotifier для фонового изображения
  final ValueNotifier<String?> backgroundImageNotifier =
      ValueNotifier<String?>(null);

  // ValueNotifier для выбранной анимации
  final ValueNotifier<String> selectedAnimationNotifier =
      ValueNotifier<String>("none");

// ValueNotifier для выбранной анимации
  final ValueNotifier<Message?> editingMessageNotifier =
      ValueNotifier<Message?>(null);

  // Очистка состояния для конкретного чата
  void disposeChatState(String chatId) {
    messagesNotifier.value = [];
    searchResultsNotifier.value = [];
    isOnlineNotifier.value = false;
    formattedLastSeenNotifier.value = '';
    selectedMessagesNotifier.value = [];
    replyMessageNotifier.value = null;
    forwardMessageNotifier.value = null;
    profileNotifier.value = {};
    isSearchingNotifier.value = false;
    showMessageInputNotifier.value = true;
    isLoadingMessagesNotifier.value = false;
    isProfileOverlayVisibleNotifier.value = false;
    backgroundImageNotifier.value = null;
    selectedAnimationNotifier.value = "none";
  }

  // Очистка всех состояний
  void disposeAll() {
    messagesNotifier.dispose();
    searchResultsNotifier.dispose();
    isOnlineNotifier.dispose();
    formattedLastSeenNotifier.dispose();
    selectedMessagesNotifier.dispose();
    replyMessageNotifier.dispose();
    forwardMessageNotifier.dispose();
    profileNotifier.dispose();
    isSearchingNotifier.dispose();
    showMessageInputNotifier.dispose();
    isLoadingMessagesNotifier.dispose();
    isProfileOverlayVisibleNotifier.dispose();
    backgroundImageNotifier.dispose();
    selectedAnimationNotifier.dispose();
  }
}
