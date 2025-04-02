import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as notifications;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shsh_social/app_state.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/utils/constants.dart';
import 'package:shsh_social/features/auth/data/models/user_model.dart';
import 'package:shsh_social/features/chat/data/services/notification_service.dart';
import 'package:shsh_social/features/chat/data/services/shared_preferences_singleton.dart';
import 'package:shsh_social/features/chat/domain/entities/message.dart';
import 'package:shsh_social/main.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../../core/data_base_helper.dart';
import '../../../auth/data/services/TokenManager.dart';

class WebSocketClientService with WidgetsBindingObserver {
  StompClient? stompClient;
  String? userId;
  bool isConnected = false;
  bool isAppInForeground = true;
  final NotificationService notificationService;
  Timer? reconnectTimer;

  /// Конструктор для создания экземпляра [WebSocketClientService].
  WebSocketClientService._private({
    required this.notificationService,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  static final WebSocketClientService _instance =
      WebSocketClientService._private(
    notificationService: NotificationService(),
  );

  static WebSocketClientService get instance => _instance;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isAppInForeground = state == AppLifecycleState.resumed;
    if (isAppInForeground) {
      _checkConnectionAndReconnectIfNeeded();
    }
  }

  /// Освобождает ресурсы и отписывается от наблюдения за жизненным циклом приложения.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reconnectTimer?.cancel();
  }

  /// Устанавливает идентификатор пользователя и подключается к WebSocket.
  Future<void> setUserIdAndConnect(String userId) async {
    this.userId = userId;
    await requestPermissions();
    await connect();
  }

  /// Сохраняет состояние подключения WebSocket в SharedPreferences.
  Future<void> saveWebSocketState(bool isConnected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWebSocketConnected', isConnected);
  }

  /// Загружает состояние подключения WebSocket из SharedPreferences.
  Future<bool> loadWebSocketState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isWebSocketConnected') ?? false;
  }

  /// Подключается к WebSocket, если подключение еще не установлено.
  Future<void> connect() async {
    if (isConnected) {
      _sendPingIfNeeded();
      return;
    }

    try {
      await _initializeStompClient();
      _startInternetCheckTimer();
      await saveWebSocketState(true);
    } catch (e) {
      _scheduleReconnect();
    }
  }

  /// Отправляет ping, если приложение находится на переднем плане.
  void _sendPingIfNeeded() {
    if (stompClient != null && isAppInForeground) {
      if (stompClient!.connected) {
        stompClient?.send(
          destination: '/app/ping',
          body: 'ping',
        );
      } else {
        _scheduleReconnect();
      }
    }
  }

  /// Инициализирует StompClient для подключения к WebSocket.
  Future<void> _initializeStompClient() async {
    try {
      if (AppState().isInternet == true) {
        final prefs = await SharedPreferencesSingleton.getInstance().value;
        final cachedUser = prefs.getString('cached_user');
        if (cachedUser != null) {
          final user = UserModel.fromJson(
              json.decode(cachedUser) as Map<String, dynamic>);
          if (user.token != null && user.token!.isNotEmpty) {
            stompClient = StompClient(
              config: StompConfig(
                url: 'ws://90.156.171.188:8080/ws?userId=${user.id}',
                onConnect: onConnect,
                stompConnectHeaders: {'Authorization': 'Bearer ${user.token}'},
                onWebSocketError: (dynamic error) =>
                    _handleWebSocketError(error),
                onStompError: (StompFrame frame) => _handleStompError(frame),
                onDisconnect: (StompFrame frame) => _handleDisconnect(frame),
              ),
            );
            stompClient?.activate();
            isConnected = true;
          }
        }
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  /// Запускает таймер для проверки интернет-соединения.
  void _startInternetCheckTimer() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (isAppInForeground) {
        _checkInternetConnection();
      }
    });
  }

  /// Проверяет наличие интернет-соединения и пытается переподключиться при его отсутствии.
  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      AppState().isInternet = false;
      isConnected = false;
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Нет доступа в интернет')),
      );
      _scheduleReconnect();
    } else {
      AppState().isInternet = true;
      if (!isConnected || (stompClient != null && !stompClient!.connected)) {
        await connect();
      }
    }
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  /// Обрабатывает подключение к WebSocket и подписывается на необходимые каналы.
  void onConnect(StompFrame connectFrame) async {
    if (userId == null) {
      return;
    }

    // Подписываемся на каналы, если есть интернет и userId не null
    if (AppState().isInternet == true) {
      stompClient?.subscribe(
        destination: '/user/$userId/queue/messages',
        callback: (StompFrame frame) {
          var msg = json.decode(frame.body!);
          onMessage(msg);
        },
      );

      stompClient?.subscribe(
        destination: '/user/$userId/queue/errors',
        callback: (StompFrame frame) {
          var msg = json.decode(frame.body!);
          displayMessage(msg);
        },
      );

      stompClient?.subscribe(
        destination: '/user/$userId/queue/events',
        callback: (StompFrame frame) {
          var msg = json.decode(frame.body!);
          displayMessage(msg);
        },
      );

      stompClient?.subscribe(
        destination: '/user/$userId/queue/messages-read',
        callback: (StompFrame frame) {
          var msg = json.decode(frame.body!);
          _handleRead(msg);
        },
      );
    }
  }

  Future<void> markMessagesAsRead({
    required List<String> messageIds,
    required String chatId,
  }) async {
    if (stompClient == null) {
      print("stompClient == null");
      return;
    }

    if (!stompClient!.connected) {
      _scheduleReconnect();
      await Future.delayed(Duration(milliseconds: 800));
    }

    try {
      final prefs = await SharedPreferencesSingleton.getInstance().value;
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser != null) {
        final userId =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
                .id;
        if (userId != null && userId.isNotEmpty) {
          int retryAttempts = 0;
          const maxRetries = 5; // Максимальное количество попыток
          bool success = false;

          while (retryAttempts < maxRetries && !success) {
            // Создаем Completer для ожидания подтверждения от сервера
            Completer<void> completer = Completer<void>();

            // Добавляем временный обработчик для подтверждения
            void onMessagesRead(String receivedChatId, String readerId,
                List<String> receivedMessageIds) {
              if (receivedChatId == chatId &&
                  _listsAreEqual(receivedMessageIds, messageIds)) {
                completer.complete(); // Завершаем ожидание
              }
            }

            // Подписываемся на временное уведомление
            AppState().temporaryMessagesReadNotification = onMessagesRead;

            try {
              // Отправляем запрос на сервер
              stompClient?.send(
                destination: '/app/messages/read',
                body: json.encode({
                  'messageIds': messageIds,
                  'readerId': userId,
                  'chatId': chatId,
                }),
              );

              // Ожидаем завершения Completer или таймаута
              await completer.future.timeout(Duration(seconds: 5));

              // Если мы дошли до этого места, значит подтверждение получено
              success = true;
              print("Messages successfully marked as read.");
            } catch (e) {
              retryAttempts++;
              print("Error during retry attempt $retryAttempts: $e");
              await Future.delayed(
                  Duration(seconds: 1)); // Задержка перед следующей попыткой
            } finally {
              // Удаляем временный обработчик
              AppState().temporaryMessagesReadNotification = null;
            }
          }

          if (!success) {
            print(
                "Failed to mark messages as read after $maxRetries attempts.");
          }
        }
      }
    } catch (e) {
      print('Error sending read receipt: $e');
    }
  }

  Future<void> sendTypingStatus({
    required String chatId,
    required String initiatorUserId,
    required bool isTyping,
  }) async {
    final hasInternet = await checkInternetConnection();
    if (stompClient == null || !hasInternet) return;
    try {
      stompClient?.send(
        destination: '/app/events/typing',
        body: json.encode({
          'chatId': chatId,
          'initiatorUserId': initiatorUserId,
          'isTyping': isTyping,
        }),
      );
    } catch (e) {
      throw Exception('Ошибка отправки статуса печатания: $e');
    }
  }

  /// Отправляет запрос на редактирование сообщения через WebSocket.
  Future<void> editPersonalMessage({
    required String messageId,
    required String chatId,
    required String senderId,
    required String newContent,
  }) async {
    if (stompClient == null) return;

    try {
      stompClient?.send(
        destination: '/app/events/editPersonalMessage',
        body: json.encode({
          'messageId': messageId,
          'chatId': chatId,
          'senderId': senderId,
          'newContent': newContent,
        }),
      );
    } catch (e) {
      throw Exception(
          'Ошибка отправки запроса на редактирование сообщения: $e');
    }
  }

  /// Удаляет сообщения из чата.
  Future<void> deleteMessages(String chatId, List<String> messageIds) async {
    if (stompClient == null) return;

    try {
      final prefs = await SharedPreferencesSingleton.getInstance().value;
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser != null) {
        final userId =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
                .id;
        if (userId != null && userId.isNotEmpty) {
          stompClient?.send(
            destination: '/app/events/deletePersonalMessage',
            body: json.encode({
              'chatId': chatId,
              'initiatorUserId': userId,
              'messageIds': messageIds,
            }),
          );
        }
      }
    } catch (e) {
      throw Exception('Ошибка отправки запроса на удаление сообщений: $e');
    }
  }

  /// Отправляет сообщение через WebSocket.
  Future<void> sendMessage(
    String recipientId,
    String chatId,
    String content, {
    String? messageType,
    String? parentMessageId,
    String? reply = "",
  }) async {
    print(stompClient!.connected);

    final hasInternet = await checkInternetConnection();
    if (stompClient == null || !hasInternet) {
      final prefs = await SharedPreferencesSingleton.getInstance().value;
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser != null) {
        final userId =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
                .id;

        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: userId,
          recipientId: recipientId,
          content: content,
          timestamp: DateTime.now().subtract(Duration(hours: 3)),
          parentMessageId: parentMessageId,
          isEdited: false,
          status: 'FAILED',
        );
        await DatabaseHelper().insertMessage(message);
        AppState().onMessageReceived!(message);
      }
      return;
    }

    try {
      final prefs = await SharedPreferencesSingleton.getInstance().value;
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser != null) {
        final userId =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
                .id;
        if (userId != null && userId.isNotEmpty) {
          stompClient?.send(
            destination: '/app/send$reply',
            body: json.encode({
              'chatId': chatId,
              'content': content,
              'senderId': userId,
              'recipientId': recipientId,
              'messageType': messageType ?? 'TEXT',
              'parentMessageId': parentMessageId,
            }),
          );
        }
      }
    } catch (e) {
      throw Exception('Ошибка отправки сообщения: $e');
    }
  }

  /// Отправляет фото-сообщение через WebSocket.
  Future<void> sendPhotoMessage(
      String recipientId, String chatId, String photoUrl) async {
    await sendMessage(recipientId, chatId, photoUrl, messageType: 'PHOTO');
  }

  /// Отправляет ответное сообщение через WebSocket.
  Future<void> sendReplyMessage(String recipientId, String chatId,
      String content, String parentMessageId) async {
    await sendMessage(recipientId, chatId, content,
        parentMessageId: parentMessageId, reply: "/reply");
  }

  /// Отключается от WebSocket.
  void disconnect() {
    stompClient?.deactivate();
    isConnected = false;
    saveWebSocketState(false);
  }

  void _handleRead(Map<String, dynamic> msg) {
    final messageIds = List<String>.from(msg['messageIds']);
    final readerId = msg['readerId'];
    final chatId = msg['chatId'];

    AppState().messagesReadNotification?.call(chatId, readerId, messageIds);

    AppState()
        .temporaryMessagesReadNotification
        ?.call(chatId, readerId, messageIds);
  }

// Проверка равенства двух списков
  bool _listsAreEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void onMessage(Map<String, dynamic> msg) async {
    final message = Message.fromJson(msg);
    if (AppState().currentChatId != null) {
      AppState().onMessageReceived?.call(message);
    } else {
      try {
        if (message.senderId.isNotEmpty) {
          final userProfile = await getUserProfileForChat(message.senderId);
          final username = userProfile['username'];

          if (message.senderId != userId) {
            notificationService.showNotification(
              title: 'Новое сообщение от $username',
              body: message.content,
            );
          }
        }

        AppState().onMessageReceivedChats?.call(message);
      } catch (e) {
        print(e);
      }
    }
  }

  /// Обрабатывает входящие сообщения и отображает их.
  void displayMessage(Map<String, dynamic> msg) async {
    if (msg['type'] == 'MESSAGE_DELETED') {
      final chatId = msg['chatId'];
      final targetMessageId = msg['targetMessageId'];
      AppState().removeMessageFromChat?.call(chatId, targetMessageId);
      return;
    }

    if (msg['type'] == 'MESSAGE_EDITED') {
      final targetMessageId = msg['targetMessageId'];
      final payload = msg['payload'];
      final newContent = payload['content'];
      final editedAt = payload['editedAt'];

      // Обновляем сообщение в текущем чате, если оно активно
      if (AppState().currentChatId != null) {
        AppState()
            .updateMessageContent
            ?.call(targetMessageId, newContent, editedAt);
      }
      return;
    }

    if (msg['type'] == 'TYPING_INDICATOR') {
      final chatId = msg['chatId'];
      final initiatorId = msg['initiatorId'];
      final isTyping = msg['payload']['isTyping'];

      AppState().updateTypingStatus(chatId, initiatorId, isTyping);
      return;
    }
  }

  /// Проверяет, находится ли пользователь в текущем чате.
  bool isUserInChat(String chatId) {
    return AppState().currentChatId == chatId;
  }

  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    _scheduleReconnect();
  }

  void _handleStompError(StompFrame frame) {
    print('STOMP error: ${frame.body}');
    _scheduleReconnect();
  }

  void _handleDisconnect(StompFrame frame) {
    print('Disconnected: ${frame.body}');
    isConnected = false;
    _scheduleReconnect();
  }

  /// Планирует повторное подключение через 5 секунд.
  void _scheduleReconnect() {
    reconnectTimer = Timer(Duration(minutes: 15), () async {
      // Перед переподключением проверяем интернет
      if (await checkInternetConnection()) {
        await connect();
      }
    });
  }

  /// Проверяет подключение и переподключается при необходимости.
  void _checkConnectionAndReconnectIfNeeded() {
    if (!isConnected) {
      connect();
    }
  }
}

/// Получает профиль пользователя для чата.
Future<Map<String, dynamic>> getUserProfileForChat(String userId) async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(
          '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Ошибка получения профиля пользователя: $e');
  }
}

/// Возвращает заголовки для HTTP-запросов.
Future<Map<String, String>> _getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedUser = prefs.getString('cached_user');
  if (cachedUser != null) {
    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  } else {
    throw ServerException('Токен недоступен');
  }
}

/// Запрашивает необходимые разрешения для работы уведомлений.
Future<void> requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
