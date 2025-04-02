import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../mini_apps/presentation/widgets/snake_game_page.dart';
import 'package:shsh_social/core/utils/AppColors.dart'; // Импортируем AppColors

import '../../../../core/data_base_helper.dart';
import '../../../settings/data/services/theme_manager.dart';
import '../../domain/entities/UserModel.dart';
import '../../domain/entities/chat.dart';
import '../../../mini_apps/presentation/widgets/custom_calendar_page.dart';

class CustomSearchDelegate extends SearchDelegate<String> {
  final String userId;

  CustomSearchDelegate({required this.userId});

  List<String> get recentSearches => List.filled(3, '');

  @override
  List<Widget> buildActions(BuildContext context) {
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    return [
      IconButton(
        icon: Icon(
          Icons.clear,
          color: colors.iconColor, // Используем цвет иконок из AppColors
        ),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
        color: colors.iconColor, // Используем цвет иконок из AppColors
      ),
      onPressed: () {
        close(context, "");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isWhiteNotifier,
        builder: (context, isWhite, child) {
          final colors = isWhite ? AppColors.light() : AppColors.dark();
          if (query.isNotEmpty) {
            return FutureBuilder<List<UserModelForChat>>(
              future: _searchUsers(query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                } else if (snapshot.hasError) {
                  if (snapshot.error
                      .toString()
                      .contains("Пользователи не найдены")) {
                    return Center(
                      child: Text(
                        'Пользователи не найдены',
                        style: TextStyle(
                          color: colors.textColor,
                        ),
                      ),
                    );
                  } else {
                    return Center(
                      child: Text(
                        'Ошибка: ${snapshot.error}',
                        style: TextStyle(
                          color: colors.textColor,
                        ),
                      ),
                    );
                  }
                } else if (snapshot.hasData) {
                  final users = snapshot.data!;
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'Пользователи не найдены',
                        style: TextStyle(
                          color: colors.textColor,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colors.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isFavorite = user.id == userId;
                      return ListTile(
                        leading: _buildAvatar(
                            colors, user.avatarUrl, user.username, isFavorite),
                        title: Text(
                          isFavorite ? 'Избранное' : user.username,
                          style: TextStyle(
                            color: colors.textColor,
                          ),
                        ),
                        subtitle: Text(
                          !isFavorite ? user.descriptionOfProfile : "",
                          style: TextStyle(
                            color: colors.textColor,
                          ),
                        ),
                        onTap: () async {
                          final dbHelper = DatabaseHelper();
                          final prefs = await SharedPreferences.getInstance();
                          final cachedUser = prefs.getString('cached_user');
                          if (cachedUser == null) {
                            throw Exception('Пользователь не найден в кэше');
                          }

                          if (cachedUser != null) {
                            try {
                              final userId = UserModel.fromJson(
                                      json.decode(cachedUser)
                                          as Map<String, dynamic>)
                                  .id;
                              if (userId != null) {
                                final existingChat = await dbHelper
                                    .getChatByUserIds(userId, user.id);
                                if (existingChat != null) {
                                  _openChatPage(
                                      context, existingChat.id, user.id);
                                } else {
                                  _openChatPage(context, null, user.id);
                                }
                              } else {
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(content: Text('Упс...')),
                                // );
                              }
                            } catch (e) {
                              print(e);
                            }
                            ;
                          }
                          ;
                        },
                      );
                    },
                  );
                } else {
                  return Container();
                }
              },
            );
          } else {
            return Container();
          }
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    final suggestions = query.isEmpty ? recentSearches : List.filled(10, '');
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(
          suggestions[index],
          style: TextStyle(
              color: colors.textColor), // Используем цвет текста из AppColors
        ),
        onTap: () {
          query = suggestions[index];
          showResults(context);
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: colors.backgroundColor,
          iconTheme: IconThemeData(color: colors.iconColor),
          titleTextStyle: TextStyle(color: colors.textColor),
        ),
        colorScheme:
            isWhiteNotifier.value ? ColorScheme.light() : ColorScheme.dark());
  }

  @override
  String get searchFieldLabel => 'Поиск пользователей';

  Future<List<UserModelForChat>> _searchUsers(String query) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await http.get(
          Uri.parse(
              '${Constants.baseUrl}${Constants.searchUsersEndpoint}?query=$query'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => UserModelForChat.fromJson(json)).toList();
      } else {
        final Map<String, dynamic> errorResponse =
            json.decode(utf8.decode(response.bodyBytes));

        if (errorResponse['message'] == "Пользователи не найдены") {
          throw Exception("Пользователи не найдены");
        } else {
          throw Exception(errorResponse['message'] ?? "Неизвестная ошибка");
        }
      }
    } catch (e) {
      throw Exception('Ошибка: $e');
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
      throw Exception('Токен недоступен');
    }
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw Exception('Пользователь не найден в кэше');
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw Exception('Токен пуст');
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      // Обновление токена
      await TokenManager.refreshToken();

      // Повторный запрос с обновленным токеном
      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw Exception(
            'Пользователь не найден в кэше после обновления токена');
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw Exception('Токен пуст после обновления');
      }

      response = await request();
    }

    return response;
  }

  void _openChatPage(
      BuildContext context, String? chatId, String recipientId) async {
    final dbHelper = DatabaseHelper();

    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw Exception('Пользователь не найден в кэше');
    }

    if (cachedUser != null) {
      try {
        final userId =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
                .id;
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

  Widget _buildAvatar(AppColors colors, String? avatarUrl, String? username,
      bool _isFavoriteChat) {
    if (_isFavoriteChat) {
      return CircleAvatar(
        backgroundColor: colors.backgroundColor,
        radius: 24,
        child: Icon(
          Icons.star,
          color: colors.primaryColor,
          size: 30,
        ),
      );
    }

    return CircleAvatar(
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      backgroundColor: colors.cardColor,
      radius: 24,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              username?.isNotEmpty == true ? username![0].toUpperCase() : '',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  bool isFavoriteChat(String userId, String chatUserId) {
    return userId == chatUserId;
  }
}
