import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../../core/data_base_helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/message.dart';
import 'shared_preferences_singleton.dart';

class WebSocketClientServiceForWorkManager {
  StompClient? stompClient;

  WebSocketClientServiceForWorkManager();

  Future<void> connect() async {
    if (stompClient != null && stompClient!.connected) {
      return;
    }

    try {
      final prefs = await SharedPreferencesSingleton.getInstance().value;
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser != null) {
        final user =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>);
        if (user.token != null && user.token!.isNotEmpty) {
          stompClient = StompClient(
            config: StompConfig(
              url: 'ws://90.156.171.188:8080/ws?userId=${user.id}',
              onConnect: onConnect,
              stompConnectHeaders: {'Authorization': 'Bearer ${user.token}'},
              onWebSocketError: (dynamic error) => _handleWebSocketError(error),
              onStompError: (StompFrame frame) => _handleStompError(frame),
              onDisconnect: (StompFrame frame) => _handleDisconnect(frame),
            ),
          );
          stompClient?.activate();
        }
      }
    } catch (e) {
      _scheduleReconnect();
    }
  }

  Future<void> onConnect(StompFrame connectFrame) async {
    final prefs = await SharedPreferencesSingleton.getInstance().value;
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      final user =
          UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>);
      stompClient?.subscribe(
        destination: '/user/${user.id}/queue/messages',
        callback: (StompFrame frame) {
          var msg = json.decode(frame.body!);
          print(msg);
          displayMessage(msg);
        },
      );
    }
  }

  Future<void> sendMessage(
    String recipientId,
    String chatId,
    String content, {
    String? messageType,
    String? parentMessageId,
    String? reply = "",
  }) async {
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

  void displayMessage(Map<String, dynamic> msg) async {}

  void _handleWebSocketError(dynamic error) {
    _scheduleReconnect();
  }

  void _handleStompError(StompFrame frame) {
    _scheduleReconnect();
  }

  void _handleDisconnect(StompFrame frame) {
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    Timer(Duration(seconds: 5), () => connect());
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
}
