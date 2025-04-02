import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../settings/data/services/theme_manager.dart'; // Импортируем AppColors
import '../../data/models/chat_model.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;

  const ChatListItem({super.key, required this.chat});

  Future<Map<String, dynamic>> getUserProfileForChat(String userId) async {
    final response = await _handleRequestWithTokenRefresh(() async {
      final headers = await _getHeaders();
      return await http.get(
        Uri.parse(
            '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
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
      throw ServerException('Токен недоступен');
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

  Future<void> _createOneToOneChat(
      BuildContext context, String firstUserId, String secondUserId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await http.post(
          Uri.parse(
              '${Constants.baseUrl}${Constants.createOneToOneChatEndpoint}'),
          headers: headers,
          body: json.encode({
            'firstUserId': firstUserId,
            'secondUserId': secondUserId,
          }),
        );
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final chatId = responseData['chatId'];
        if (chatId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('chatId_$secondUserId', chatId);
          _openChatPage(context, chatId, secondUserId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка: chatId не получен')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сервера: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _openChatPage(
      BuildContext context, String chatId, String recipientId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      try {
        final userMap = json.decode(cachedUser) as Map<String, dynamic>;
        final userId = UserModel.fromJson(userMap).id;
        if (userId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                chatId: chatId,
                userId: userId,
                recipientId: recipientId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Упс...')),
          );
        }
      } catch (e) {
        print('Error decoding cached user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Упс...')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Упс...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    return FutureBuilder<Map<String, dynamic>>(
      future: getUserProfileForChat(chat.user2Id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: colors.cardColor, // Используем цвет карточки из AppColors
            child: ListTile(
              leading: CircularProgressIndicator(
                color: colors
                    .primaryColor, // Используем основной цвет из AppColors
              ),
              title: Text(
                'Загрузка...',
                style: TextStyle(
                    color: colors
                        .textColor), // Используем цвет текста из AppColors
              ),
              trailing: Icon(
                Icons.chat_bubble_outline,
                color: colors.iconColor, // Используем цвет иконок из AppColors
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: colors.cardColor, // Используем цвет карточки из AppColors
            child: ListTile(
              title: Text(
                'Ошибка: ${snapshot.error}',
                style: TextStyle(
                    color: colors
                        .textColor), // Используем цвет текста из AppColors
              ),
              trailing: Icon(
                Icons.chat_bubble_outline,
                color: colors.iconColor, // Используем цвет иконок из AppColors
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final profileData = snapshot.data!;
          final username = profileData['username'] ?? '';
          final avatarUrl = profileData['avatarUrl'] ?? '';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: colors.cardColor, // Используем цвет карточки из AppColors
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                backgroundColor:
                    colors.backgroundColor, // Используем цвет фона из AppColors
                radius: 24,
                child: avatarUrl.isEmpty
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '',
                        style: TextStyle(
                          color: colors
                              .textColor, // Используем цвет текста из AppColors
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              title: Text(
                username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      colors.textColor, // Используем цвет текста из AppColors
                ),
              ),
              trailing: Icon(
                Icons.chat_bubble_outline,
                color: colors.iconColor, // Используем цвет иконок из AppColors
              ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final cachedUser = prefs.getString('cached_user');
                if (cachedUser != null) {
                  try {
                    final userMap =
                        json.decode(cachedUser) as Map<String, dynamic>;
                    final userId = UserModel.fromJson(userMap).id;
                    print('userId: $userId');
                    if (userId != null) {
                      final chatId = prefs.getString('chatId_${chat.user2Id}');
                      print('== $chatId');
                      if (chatId != null) {
                        _openChatPage(context, chatId, chat.user2Id);
                      } else {
                        await _createOneToOneChat(
                            context, userId, chat.user2Id);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Упс...')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Упс...')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Упс...')),
                  );
                }
              },
            ),
          );
        } else {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: colors.cardColor, // Используем цвет карточки из AppColors
            child: ListTile(
              title: Text(
                'Нет данных',
                style: TextStyle(
                    color: colors
                        .textColor), // Используем цвет текста из AppColors
              ),
              trailing: Icon(
                Icons.chat_bubble_outline,
                color: colors.iconColor, // Используем цвет иконок из AppColors
              ),
            ),
          );
        }
      },
    );
  }
}
