import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/services/TokenManager.dart';
import '../../features/main/data/services/data_manager.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/chat/domain/entities/message.dart';
import '../data_base_helper.dart';
import '../error/exceptions.dart';
import 'constants.dart';

class SyncManager {
  final DatabaseHelper dbHelper;

  SyncManager(this.dbHelper);

  Future<void> syncChatsWithServer(String userId) async {
    try {
      final headers = await _getHeaders();
      final chats = await dbHelper.getChats();

      final requestBody = {
        "chats": chats
            .map((chat) => {
                  "chatId": chat.id,
                  "lastSequence": chat.lastSequence,
                })
            .toList(),
      };

      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await http.post(
          Uri.parse('${Constants.baseUrl}/chats/sync'),
          headers: headers,
          body: json.encode(requestBody),
        );
      });
      if (response.statusCode == 200) {
        await _handleSyncResponse(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw ServerException('Sync failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw CacheException();
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw CacheException();
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      // Обновление токена
      await TokenManager.refreshToken();

      // Повторный запрос с обновленным токеном
      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw CacheException();
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw CacheException();
      }

      response = await request();
    }

    return response;
  }

  Future<void> _handleSyncResponse(Map<String, dynamic> responseData) async {
    // Check if 'results' is null
    final results = responseData['results'];
    if (results == null) {
      print('Error: results is null');
      return;
    }

    final globalUpdates = responseData['globalUpdates'];

    for (final chatId in results.keys) {
      final chatData = results[chatId];
      if (chatData == null) {
        print('Error: chatData is null for chatId $chatId');
        continue;
      }

      final serverSequence = chatData['serverSequence'] as int;
      final newMessages = (chatData['newMessages'] as List?)
              ?.map((msg) => Message.fromJson(msg))
              .toList() ??
          [];

      final statusUpdates = chatData['statusUpdates'] as Map<String, dynamic>?;
      final validStatusUpdates = statusUpdates?.map((key, value) {
        if (value is Map<String, dynamic> && value.containsKey('newStatus')) {
          return MapEntry(key, value['newStatus']);
        } else {
          print(
              'Warning: Unexpected value format in statusUpdates for key $key');
          return MapEntry(key, 'UNKNOWN'); // Handle unexpected value formats
        }
      });

      final deletedMessageIds =
          List<String>.from(chatData['deletedMessageIds'] ?? []);
      final edits = (chatData['edits'] as List?)
              ?.map((edit) => {
                    'messageId': edit['messageId'],
                    'newContent': edit['newContent'],
                  })
              .toList() ??
          [];

      final chat = await dbHelper.getChatById(chatId);

      if (chat != null) {
        for (final message in newMessages) {
          await dbHelper.insertMessage(message);
        }

        if (validStatusUpdates != null) {
          for (final messageId in validStatusUpdates.keys) {
            final status = validStatusUpdates[messageId];
            await dbHelper.updateMessageStatus(messageId, status);
          }
        } else {
          print('Warning: validStatusUpdates is null');
        }

        for (final messageId in deletedMessageIds) {
          await dbHelper.deleteMessage(messageId);
        }

        for (final edit in edits) {
          final messageId = edit['messageId'];
          final newContent = edit['newContent'];
          final message = (await dbHelper.getMessages(chatId))
              .firstWhereOrNull((msg) => msg.id == messageId);
          if (message != null) {
            message.content = newContent;
            await dbHelper.updateMessage(message, isEdited: true);
          }
        }
        final userId = await loadUserId();
        final notReadCount = newMessages
            .where((msg) =>
                (msg.status == 'SENT' || msg.status == 'DELIVERED') &&
                msg.senderId != userId)
            .length;
        chat.notRead = notReadCount;
        chat.lastSequence = serverSequence;
        await dbHelper.updateChat(chat);
      } else {
        print('Chat $chatId not found in database');
      }
    }

    if (globalUpdates != null && globalUpdates.containsKey('deletedChats')) {
      final deletedChats =
          List<String>.from(globalUpdates['deletedChats'] ?? []);
      for (final chatId in deletedChats) {
        await dbHelper.deleteChat(chatId);
        await dbHelper.deleteMessagesByChatId(chatId);
      }
    }
  }

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
      throw ServerException('Token not available');
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
}
