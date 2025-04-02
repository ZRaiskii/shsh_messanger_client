// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shsh_social/app_state.dart';
// import 'package:shsh_social/core/app_settings.dart';
// import 'package:shsh_social/core/utils/KeysManager.dart';
// import 'package:shsh_social/features/auth/data/services/TokenManager.dart';
// import 'package:shsh_social/features/chat/data/services/stomp_client.dart';
// import 'package:shsh_social/features/chat/presentation/pages/chat_page.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'
//     as fln;
// import 'package:huawei_push/huawei_push.dart' as huawei;

// class HuaweiPushService {
//   static final HuaweiPushService _instance = HuaweiPushService._internal();
//   factory HuaweiPushService() => _instance;
//   HuaweiPushService._internal();

//   final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
//       fln.FlutterLocalNotificationsPlugin();

//   Future<void> init() async {
//     await _initPushKit();
//     await _setupNotifications();
//     _registerMessageHandlers();
//     await _handleInitialNotifications();
//   }

//   Future<void> _initPushKit() async {
//     try {
//       await huawei.Push.setAutoInitEnabled(true);
//       await _setupTokenStream();
//       await _setupIntentStreams();
//       await _setupMessageStreams();
//       await _registerBackgroundHandler();
//     } catch (e) {
//       debugPrint('Huawei Push init error: $e');
//     }
//   }

//   void _registerMessageHandlers() {
//     // Дополнительные обработчики сообщений при необходимости
//   }

//   Future<void> _setupTokenStream() async {
//     huawei.Push.getTokenStream.listen(
//       _onTokenEvent,
//       onError: (error) => _onTokenError(error),
//     );
//   }

//   Future<void> _setupIntentStreams() async {
//     huawei.Push.getIntentStream.listen(
//       _onNewIntent,
//       onError: (error) => _onIntentError(error),
//     );
//   }

//   Future<void> _setupMessageStreams() async {
//     huawei.Push.onMessageReceivedStream.listen(
//       _onMessageReceived,
//       onError: (error) => _onMessageReceiveError(error),
//     );

//     huawei.Push.getRemoteMsgSendStatusStream.listen(
//       _onRemoteMessageSendStatus,
//       onError: (error) => _onRemoteMessageSendError(error),
//     );
//   }

//   Future<void> _registerBackgroundHandler() async {
//     await huawei.Push.registerBackgroundMessageHandler(
//         backgroundMessageHandler);
//   }

//   Future<void> _handleInitialNotifications() async {
//     final dynamic initialNotification =
//         await huawei.Push.getInitialNotification();
//     if (initialNotification != null) {
//       _processNotificationData(initialNotification);
//     }

//     final String? initialIntent = await huawei.Push.getInitialIntent();
//     if (initialIntent != null) {
//       _processIntentData(initialIntent);
//     }
//   }

//   void _processNotificationData(dynamic data) {
//     // Обработка данных уведомления
//   }

//   void _onTokenEvent(String token) async {
//     if (token.isNotEmpty) {
//       await KeysManager.write('huawei_token', token);
//       debugPrint('Huawei Push Token: $token');
//     }
//   }

//   void _onTokenError(Object error) {
//     final e = error as PlatformException;
//     debugPrint('Token Error: ${e.message}');
//   }

//   void _onMessageReceived(huawei.RemoteMessage message) async {
//     debugPrint('Huawei Push message received: ${message.data}');
//     if (!_shouldShowNotification(message)) return;

//     await _showHuaweiNotification(message);
//     _vibrateDevice();
//   }

//   bool _shouldShowNotification(huawei.RemoteMessage message) {
//     try {
//       final data = message.data as Map<String, dynamic>? ?? {};
//       final notificationChatId = data['chatId']?.toString();
//       final currentChatId = AppState().currentChatId?.toString();

//       return AppSettings.inAppNotifications &&
//           notificationChatId != null &&
//           notificationChatId != currentChatId;
//     } catch (e) {
//       debugPrint('Error checking notification: $e');
//       return true;
//     }
//   }

//   void _onMessageReceiveError(Object error) {
//     debugPrint('Message Receive Error: $error');
//   }

//   void _onRemoteMessageSendStatus(String status) {
//     debugPrint('Message Send Status: $status');
//   }

//   void _onRemoteMessageSendError(Object error) {
//     debugPrint('Message Send Error: $error');
//   }

//   void _onNewIntent(String? intent) {
//     if (intent != null && intent.isNotEmpty) {
//       _processIntentData(intent);
//     }
//   }

//   void _onIntentError(Object error) {
//     debugPrint('Intent Error: $error');
//   }

//   Future<void> _processIntentData(String intent) async {
//     try {
//       final data = _parseIntentData(intent);
//       if (data['chatId'] != null && data['senderId'] != null) {
//         _navigateToChat(data);
//       }
//     } catch (e) {
//       debugPrint('Error processing intent: $e');
//     }
//   }

//   Map<String, dynamic> _parseIntentData(String intent) {
//     try {
//       return jsonDecode(intent) as Map<String, dynamic>;
//     } catch (e) {
//       return {};
//     }
//   }

//   void _navigateToChat(Map<String, dynamic> data) {
//     final context = navigatorKey.currentContext;
//     if (context != null) {
//       openChatPage(
//         context,
//         data['chatId']?.toString() ?? '',
//         data['senderId']?.toString() ?? '',
//       );
//     } else {
//       _savePendingAction(data);
//     }
//   }

//   Future<void> _savePendingAction(Map<String, dynamic> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('huawei_pending_action', jsonEncode(data));
//   }

//   Future<void> _setupNotifications() async {
//     const androidInitializationSettings =
//         fln.AndroidInitializationSettings('ic_launcher');

//     await _notificationsPlugin.initialize(
//       const fln.InitializationSettings(android: androidInitializationSettings),
//       onDidReceiveNotificationResponse: _handleNotificationResponse,
//     );
//   }

//   Future<void> _showHuaweiNotification(huawei.RemoteMessage message) async {
//     final data = message.data as Map<String, dynamic>? ?? {};
//     const channel = fln.AndroidNotificationChannel(
//       'chat_messages',
//       'Сообщения чата',
//       description: 'Уведомления о новых сообщениях в чатах',
//       importance: fln.Importance.high,
//     );

//     final androidDetails = fln.AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: channel.description,
//       icon: 'ic_launcher',
//       color: const Color(0xFF2196F3),
//       priority: fln.Priority.high,
//       visibility: fln.NotificationVisibility.public,
//       category: fln.AndroidNotificationCategory.message,
//       actions: [
//         const fln.AndroidNotificationAction(
//           'reply',
//           'Ответить',
//           showsUserInterface: true,
//           cancelNotification: false,
//           inputs: [
//             fln.AndroidNotificationActionInput(label: 'Введите ваш ответ')
//           ],
//         ),
//       ],
//     );

//     await _notificationsPlugin.show(
//       (data['messageId']?.toString().hashCode ?? DateTime.now().hashCode),
//       data['title']?.toString() ?? 'Новое сообщение',
//       data['body']?.toString() ?? '',
//       fln.NotificationDetails(android: androidDetails),
//       payload: jsonEncode({
//         'chatId': data['chatId']?.toString(),
//         'messageId': data['messageId']?.toString(),
//         'senderId': data['senderId']?.toString(),
//       }),
//     );
//   }

//   void _handleNotificationResponse(fln.NotificationResponse response) async {
//     if (response.payload == null) return;

//     try {
//       final data = jsonDecode(response.payload!) as Map<String, dynamic>;
//       final context = navigatorKey.currentContext;

//       switch (response.actionId) {
//         case 'reply':
//           final userReply = response.input;
//           if (userReply?.isNotEmpty ?? false) {
//             data['reply'] = userReply;
//             _sendMessage(data);
//             await _notificationsPlugin.cancel(
//               (data['messageId']?.toString().hashCode ?? 0),
//             );
//           }
//           break;
//         default:
//           if (context != null) {
//             openChatPage(
//               context,
//               data['chatId']?.toString() ?? '',
//               data['senderId']?.toString() ?? '',
//             );
//           } else {
//             await _saveActionToCache('open_chat', data);
//           }
//           break;
//       }
//     } catch (e) {
//       debugPrint('Error handling notification response: $e');
//     }
//   }

//   void _sendMessage(dynamic data) {
//     try {
//       final recipientId = data['senderId']?.toString() ?? '';
//       final chatId = data['chatId']?.toString() ?? '';
//       final content = data['reply']?.toString() ?? '';

//       // Реализация отправки сообщения через WebSocket
//       WebSocketClientService.instance.sendMessage(
//         recipientId,
//         chatId,
//         content,
//       );
//     } catch (e) {
//       debugPrint('Ошибка отправки сообщения: $e');
//     }
//   }

//   Future<void> _saveActionToCache(
//       String action, Map<String, dynamic> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('huawei_notification_action', action);
//     await prefs.setString('huawei_notification_data', jsonEncode(data));
//   }

//   void _vibrateDevice() {
//     // Пример реализации вибрации
//     try {
//       HapticFeedback.vibrate();
//     } catch (e) {
//       debugPrint('Ошибка вибрации: $e');
//     }
//   }

//   static void openChatPage(
//     BuildContext context,
//     String chatId,
//     String senderId, {
//     bool focusInput = false,
//   }) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChatPage(
//           chatId: chatId,
//           recipientId: senderId,
//           userId: '',
//         ),
//       ),
//     );
//   }
// }

// Future<void> backgroundMessageHandler(huawei.RemoteMessage message) async {
//   final service = HuaweiPushService();
//   await service._showHuaweiNotification(message);
// }
