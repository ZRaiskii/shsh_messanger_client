import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CallingNotificationManager {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  VoidCallback? onAnswerCall;
  VoidCallback? onDeclineCall;
  VoidCallback? onMuteMicrophone;

  CallingNotificationManager({
    this.onAnswerCall,
    this.onDeclineCall,
    this.onMuteMicrophone,
  });

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'call_channel',
      'Call Notifications',
      description: 'Channel for call notifications',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showCallNotification({
    required String title,
    required String body,
    required List<String> actions,
  }) async {
    List<AndroidNotificationAction> androidActions = actions.map((action) {
      return AndroidNotificationAction(
        action,
        action,
        showsUserInterface: true,
        cancelNotification: true,
      );
    }).toList();

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      actions: androidActions,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'call_notification',
    );
  }

  Future<void> cancelNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(0);
  }

  void _onSelectNotification(NotificationResponse notificationResponse) {
    print('Notification payload: ${notificationResponse.payload}');
    print('Notification action ID: ${notificationResponse.actionId}');

    if (notificationResponse.payload != null) {
      String action = notificationResponse.actionId ?? '';
      switch (action) {
        case 'Ответить':
          if (onAnswerCall != null) {
            onAnswerCall!();
          }
          break;
        case 'Сбросить':
          if (onDeclineCall != null) {
            onDeclineCall!();
          }
          break;
        case 'Выключить микрофон':
          if (onMuteMicrophone != null) {
            onMuteMicrophone!();
          }
          break;
        default:
          break;
      }
    }
  }
}
