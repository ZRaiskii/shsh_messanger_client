import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../features/auth/data/services/TokenManager.dart';
import 'package:vibration/vibration.dart'; // Для вибрации
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Для локальных уведомлений
import 'package:http/http.dart' as http;
import '../../features/auth/data/models/user_model.dart';
import '../../features/chat/data/services/notification_service.dart';
import '../../features/chat/data/services/stomp_client.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../app_settings.dart';
import 'KeysManager.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool isFlutterLocalNotificationsInitialized = false;

Future<void> init() async {
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await _flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: initializationSettingsAndroid),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload == null) return;

      // Декодируем payload
      final data = jsonDecode(response.payload!);
      final context = navigatorKey.currentContext;
      if (context == null) return;

      print('Notification action: ${response.actionId}');
      print('Payload data: $data');

      switch (response.actionId) {
        case 'reply':
          final userReply = response.input;
          if (userReply != null && userReply.isNotEmpty) {
            data['reply'] = userReply;

            _sendMessage(data);

            final notificationId = data['messageId'].hashCode;
            await _flutterLocalNotificationsPlugin.cancel(notificationId);
          }
          break;

        case 'mark_read':
          print("read at notiffiaction");
          _markMessagesAsRead(data['messageId'], data['chatId']);
          break;

        default:
          if (context != null) {
            openChatPage(context, data['chatId'], data['senderId']);
          } else {
            await _saveActionToCache('open_chat', data);
          }
          break;
      }
    },
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Разрешение на уведомления получено");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("Предварительное разрешение на уведомления получено");
  } else {
    print("Разрешение на уведомления не получено");
  }

  String? token = await messaging.getToken();
  await KeysManager.write('fcm_token', token!);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("Новое сообщение в foreground: ${message.data}");

    String? userId = message.data['userId'];
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];
    String? imageUrl = message.data['imageUrl'];
    Map<String, dynamic>? data = message.data;

    _showNotification(message: message);
  });
}

void _sendMessage(dynamic data) async {
  try {
    String recipientId = data['senderId'];
    String chatId = data['chatId'];
    String content = data['reply'];
    ;
    final userId = await loadUserId();

    WebSocketClientService webSocketService = WebSocketClientService.instance;
    await webSocketService.setUserIdAndConnect(userId);

    if (!webSocketService.isConnected) {
      print('WebSocket не подключен. Попытка переподключения...');
      await webSocketService.connect();
    }

    await webSocketService.sendMessage(recipientId, chatId, content);
  } catch (e) {
    print('Ошибка отправки сообщения: $e');
  }
}

void _markMessagesAsRead(List<String> messageIds, String chatId) async {
  final userId = await loadUserId();

  WebSocketClientService webSocketService = WebSocketClientService.instance;
  await webSocketService.setUserIdAndConnect(userId);

  if (!webSocketService.isConnected) {
    print('WebSocket не подключен. Попытка переподключения...');
    await webSocketService.connect();
  }

  try {
    await webSocketService.markMessagesAsRead(
      chatId: chatId,
      messageIds: messageIds,
    );
    print('reading: ${messageIds}');
  } catch (e) {
    print('Ошибка отправки события прочтения сообщений: $e');
  }
}

Future<String> loadUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedUser = prefs.getString('cached_user');
  if (cachedUser != null) {
    try {
      final userMap = json.decode(cachedUser) as Map<String, dynamic>;
      final userId = UserModel.fromJson(userMap).id;
      return userId;
    } catch (e) {
      throw Exception('Error loading user ID: $e');
    }
  }
  return '';
}

@pragma('vm:entry-point')
Future<void> _showNotification({required RemoteMessage message}) async {
  if (!AppSettings.inAppNotifications ||
      AppState().currentChatId == message.data['chatId']) {
    return;
  }

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',
    'Сообщения чата',
    description: 'Уведомления о новых сообщениях в чатах',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 3. Загрузка изображений
  final String? userAvatarUrl = message.data['userAvatarUrl'];

  FilePathAndroidBitmap? largeIcon;
  BigPictureStyleInformation? bigPictureStyle;

  try {
    // Загрузка аватара пользователя для круга
    if (userAvatarUrl != null) {
      final avatarPath = await _downloadAndSaveImage(userAvatarUrl);
      largeIcon = FilePathAndroidBitmap(avatarPath);
    }
  } catch (e) {
    print('Ошибка обработки изображений: $e');
  }

  final String? imageUrl = message.data['imageUrl'];
  String? imagePath;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      imagePath = await _downloadAndSaveImage(imageUrl);
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
    }
  }

  final actions = [
    const AndroidNotificationAction(
      'reply',
      'Ответить',
      showsUserInterface: true,
      cancelNotification: false,
      inputs: [
        AndroidNotificationActionInput(
          label: 'Введите ваш ответ',
        ),
      ],
    ),
    // const AndroidNotificationAction(
    //   'mark_read',
    //   'Прочитать',
    //   cancelNotification: true,
    // ),
  ];

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    icon: 'ic_launcher',
    color: const Color(0xFF2196F3),
    largeIcon: largeIcon,
    styleInformation: imagePath != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            contentTitle: message.data['title'],
            htmlFormatContentTitle: true,
            summaryText: message.data['body'],
            htmlFormatSummaryText: true,
          )
        : BigTextStyleInformation(
            message.data['body'] ?? '',
            contentTitle: message.data['title'],
            htmlFormatContentTitle: true,
            htmlFormatBigText: true,
          ),
    actions: actions,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.message,
    autoCancel: true,
    timeoutAfter: message.data['ttl'] != null
        ? int.tryParse(message.data['ttl']) ?? 86400
        : 86400,
  );

  await _flutterLocalNotificationsPlugin.show(
    message.data['messageId'].hashCode,
    message.data['title'],
    message.data['body'],
    NotificationDetails(android: androidDetails),
    payload: jsonEncode({
      'chatId': message.data['chatId'],
      'messageId': message.data['messageId'],
      'senderId': message.data['senderId'],
    }),
  );
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<String> _downloadAndSaveFile(String url) async {
  final response = await http.get(Uri.parse(url));
  final documentDirectory = await getApplicationDocumentsDirectory();
  final file = File('${documentDirectory.path}/${url.hashCode}.jpg');
  await file.writeAsBytes(response.bodyBytes);
  return file.path;
}

void _vibrate() {
  if (Vibration.hasVibrator() != null) {
    Vibration.vibrate(duration: 500);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppSettings.inAppNotifications) {
    return;
  }

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_notification', jsonEncode(message.data));

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await _flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: initializationSettingsAndroid),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload == null) return;

      // Декодируем payload
      final data = jsonDecode(response.payload!);
      final context = navigatorKey.currentContext;
      if (context == null) return;

      print('Notification action: ${response.actionId}');
      print('Payload data: $data');

      switch (response.actionId) {
        case 'reply':
          final userReply = response.input;
          if (userReply != null && userReply.isNotEmpty) {
            data['reply'] = userReply;

            _sendMessage(data);

            final notificationId = data['messageId'].hashCode;
            await _flutterLocalNotificationsPlugin.cancel(notificationId);
          }
          break;

        case 'mark_read':
          print("read at notiffiaction");
          _markMessagesAsRead(data['messageId'], data['chatId']);
          break;

        default:
          if (context != null) {
            openChatPage(context, data['chatId'], data['senderId']);
          } else {
            await _saveActionToCache('open_chat', data);
          }
          break;
      }
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',
    'Сообщения чата',
    description: 'Уведомления о новых сообщениях в чатах',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final String? userAvatarUrl = message.data['userAvatarUrl'];

  FilePathAndroidBitmap? largeIcon;
  BigPictureStyleInformation? bigPictureStyle;

  try {
    if (userAvatarUrl != null) {
      final avatarPath = await _downloadAndSaveImage(userAvatarUrl);
      largeIcon = FilePathAndroidBitmap(avatarPath);
    }
  } catch (e) {
    print('Ошибка обработки изображений: $e');
  }

  final String? imageUrl = message.data['imageUrl'];
  String? imagePath;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      imagePath = await _downloadAndSaveImage(imageUrl);
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
    }
  }

  final actions = [
    // const AndroidNotificationAction(
    //   'reply',
    //   'Ответить',
    //   showsUserInterface: true,
    //   cancelNotification: false,
    //   inputs: [
    //     AndroidNotificationActionInput(
    //       label: 'Введите ваш ответ',
    //     ),
    //   ],
    // ),
    // const AndroidNotificationAction(
    //   'mark_read',
    //   'Прочитать',
    //   cancelNotification: true,
    // ),
  ];

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    icon: 'ic_launcher',
    color: const Color(0xFF2196F3),
    largeIcon: largeIcon,
    styleInformation: imagePath != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            contentTitle: message.data['title'],
            htmlFormatContentTitle: true,
            summaryText: message.data['body'],
            htmlFormatSummaryText: true,
          )
        : BigTextStyleInformation(
            message.data['body'] ?? '',
            contentTitle: message.data['title'],
            htmlFormatContentTitle: true,
            htmlFormatBigText: true,
          ),
    // actions: actions,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.message,
    autoCancel: true,
    timeoutAfter: message.data['ttl'] != null
        ? int.tryParse(message.data['ttl']) ?? 86400
        : 86400,
  );

  await _flutterLocalNotificationsPlugin.show(
    message.data['messageId'].hashCode,
    message.data['title'],
    message.data['body'],
    NotificationDetails(android: androidDetails),
    payload: jsonEncode(message.data),
  );
}

Future<String> _downloadAndSaveImage(String url) async {
  final response = await http.get(Uri.parse(url));
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${url.hashCode}.png');
  await file.writeAsBytes(response.bodyBytes);
  return file.path;
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) return;

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  isFlutterLocalNotificationsInitialized = true;
}

void openChatPage(
  BuildContext context,
  String chatId,
  String senderId, {
  bool focusInput = false,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) return;

    final user = UserModel.fromJson(json.decode(cachedUser));
    if (user.id == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chatId,
          userId: user.id!,
          recipientId: senderId,
          // autoFocus: focusInput,
        ),
      ),
    );
  } catch (e) {
    print('Error opening chat: $e');
  }
}

Future<void> _saveActionToCache(
    String action, Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('notification_action', action);
  await prefs.setString('notification_data', jsonEncode(data));
}

Future<void> _checkPendingNotifications() async {
  // Проверка сохраненных уведомлений
  final prefs = await SharedPreferences.getInstance();
  final pendingNotification = prefs.getString('pending_notification');

  if (pendingNotification != null) {
    final data = jsonDecode(pendingNotification) as Map<String, dynamic>;
    await _processNotificationData(data);
    await prefs.remove('pending_notification');
  }
}

void _handleNotification(RemoteMessage message) {
  _processNotificationData(message.data);
}

Future<void> _processNotificationData(Map<String, dynamic> data) async {
  try {
    // Проверка обязательных полей
    if (data['chatId'] == null || data['senderId'] == null) {
      throw Exception('Invalid notification data');
    }

    // Проверка аутентификации пользователя
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) throw Exception('User not authenticated');

    final user = UserModel.fromJson(json.decode(cachedUser));
    if (user.id == null) throw Exception('Invalid user data');

    // Навигация с использованием глобального ключа
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: data['chatId'].toString(),
          userId: user.id!,
          recipientId: data['senderId'].toString(),
        ),
      ),
    );
  } catch (e) {
    print('Error processing notification: $e');
    // Показать пользователю сообщение об ошибке
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(content: Text('Ошибка открытия чата: ${e.toString()}')),
    );
  }
}
