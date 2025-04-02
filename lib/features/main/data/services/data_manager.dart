import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../app_state.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/lasr_message.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/data_base_helper.dart';
import '../../../../core/utils/sync_manager.dart';
import '../../../chat/domain/entities/message.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  final ValueNotifier<List<Chat>> chatsNotifier = ValueNotifier<List<Chat>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> isSelectedNotifier =
      ValueNotifier<List<String>>([]);
  Timer? _backgroundUpdateTimer;
  final SyncManager syncManager;

  factory DataManager() {
    return _instance;
  }

  DataManager._internal() : syncManager = SyncManager(DatabaseHelper()) {
    _startBackgroundUpdates();
  }

  void _startBackgroundUpdates() {
    _backgroundUpdateTimer =
        Timer.periodic(Duration(seconds: 15), (timer) async {
      final userId = await loadUserId();
      if (userId.isNotEmpty) {
        await syncManager.syncChatsWithServer(userId);
      }
    });
  }

  // Метод для остановки фонового обновления данных
  void stopBackgroundUpdates() {
    _backgroundUpdateTimer?.cancel();
  }

  // Метод для сортировки чатов
  void sortChats(List<Chat> chats) {
    chats.sort((a, b) {
      final aCreatedAt =
          a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreatedAt =
          b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreatedAt.compareTo(aCreatedAt);
    });
    updateChats(chats);
  }

  Function(String)? onError;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void updateChats(List<Chat> chats) {
    chatsNotifier.value = chats;
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isLoadingNotifier.value = false;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
    }
    isLoadingNotifier.value = true;
    return false;
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

  Future<void> loadChats(String userId) async {
    try {
      isLoadingNotifier.value = true;
      final hasInternet = await checkInternetConnection();

      List<Chat> chats;
      if (hasInternet) {
        chats = await getChats(userId);
        await saveChatsToCache(chats);
      } else {
        // Используем кешированные данные
        chats = await getCachedChats() ?? [];
      }

      for (final chat in chats) {
        chat.notRead = await getNotReadCountForChat(chat.id, userId);
      }
      for (final chat in chats) {
        final lastMessage =
            await syncManager.dbHelper.getLastMessageForChat(chat.id);
        chat.lastMessage = lastMessage;
      }

      sortChats(chats);
      updateChats(chats);

      if (hasInternet) {
        _startBackgroundUpdates();
      }
    } catch (e) {
      onError?.call('Ошибка при загрузке чатов: $e');
      // При ошибке пробуем загрузить из кеша
      final cachedChats = await getCachedChats() ?? [];
      updateChats(cachedChats);
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  void updateUnreadMessageCount(String userId) async {
    try {
      final chats = await syncManager.dbHelper.getChats();
      for (final chat in chats) {
        chat.notRead = await getNotReadCountForChat(chat.id, userId);
      }
      updateChats(chats);
    } catch (e) {
      onError?.call(
          'Ошибка при обновлении количества непрочитанных сообщений: $e');
    }
  }

  Future<List<Chat>> getChats(String userId) async {
    final hasInternet = await checkInternetConnection();
    if (hasInternet) {
      try {
        final serverChats = await _fetchChatsFromServer(userId);
        await saveChatsToCache(serverChats);

        final dbHelper = DatabaseHelper();
        final cachedChats = await dbHelper.getChats();
        final serverChatIds = serverChats.map((c) => c.id).toSet();
        for (final chat in cachedChats) {
          if (!serverChatIds.contains(chat.id)) {
            await dbHelper.deleteChat(chat.id);
          }
        }

        var updatedCachedChats = await getCachedChats();

        for (final chat in updatedCachedChats!) {
          chat.notRead = await getNotReadCountForChat(chat.id, userId);
          chat.lastMessage = await dbHelper.getLastMessageForChat(chat.id);
        }
        sortChats(updatedCachedChats);
        return updatedCachedChats;
      } catch (e) {
        print(e);
        final cachedChats = await getCachedChats();
        return cachedChats ?? [];
      }
    } else {
      final cachedChats = await getCachedChats();
      return cachedChats ?? [];
    }
  }

  Future<void> saveChatsToCache(List<Chat> serverChats) async {
    final dbHelper = DatabaseHelper();
    for (var serverChat in serverChats) {
      final existingChat = await dbHelper.getChatById(serverChat.id);
      if (existingChat != null) {
        final updatedChat = Chat(
          id: serverChat.id,
          user1Id: serverChat.user1Id,
          user2Id: serverChat.user2Id,
          createdAt: serverChat.createdAt,
          username: serverChat.username,
          email: serverChat.email,
          descriptionOfProfile: serverChat.descriptionOfProfile,
          status: serverChat.status,
          lastMessage: serverChat.lastMessage,
          notRead: serverChat.notRead,
          lastSequence: existingChat.lastSequence,
        );
        await dbHelper.updateChat(updatedChat);
      } else {
        await dbHelper.insertChat(serverChat);
      }
    }
  }

  Future<List<Chat>?> getCachedChats() async {
    final db = DatabaseHelper();
    final chats = await db.getChats();

    if (chats != null) {
      return chats;
    }
    return [];
  }

  Future<List<Chat>> _fetchChatsFromServer(String userId) async {
    final headers = await _getHeaders();
    final response = await http
        .get(
          Uri.parse('${Constants.baseUrl}/chats/v2/allChats?userId=$userId'),
          headers: headers,
        )
        .timeout(Duration(seconds: 20));
    if (response.statusCode == 200) {
      final List<dynamic> chatsJson =
          json.decode(utf8.decode(response.bodyBytes));
      return chatsJson.map((json) => Chat.fromJson(json)).toList()
        ..sort((a, b) => _compareLastMessages(a, b));
    }
    throw ServerException('Ошибка сервера: ${response.statusCode}');
  }

  int _compareLastMessages(Chat a, Chat b) {
    final aTime = a.lastMessage?.timestamp ?? DateTime(1970);
    final bTime = b.lastMessage?.timestamp ?? DateTime(1970);
    return bTime.compareTo(aTime);
  }

  Future<int> getNotReadCountForChat(String chatId, String userId) async {
    final messages = await syncManager.dbHelper.getMessages(chatId);
    return messages.where((message) {
      if (message.status == 'SENT') {
        // print(message.content);
      }
      return (message.status == 'SENT' || message.status == 'DELIVERED') &&
          message.senderId != userId;
    }).length;
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('${Constants.baseUrl}/chats/deleteChat/$chatId'),
            headers: headers,
          )
          .timeout(Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      await syncManager.dbHelper.deleteChat(chatId);
      await syncManager.dbHelper.deleteMessagesByChatId(chatId);

      final updatedChats = await syncManager.dbHelper.getChats();
      chatsNotifier.value = updatedChats;
    } catch (e) {
      print('Ошибка при удалении чата: $e');
      throw Exception('Ошибка при удалении чата: $e');
    }
  }

  Future<void> pinChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final pinnedChats = prefs.getStringList('pinned_chats') ?? [];
    if (!pinnedChats.contains(chatId)) {
      pinnedChats.add(chatId);
      await prefs.setStringList('pinned_chats', pinnedChats);
    }
  }

  Future<void> unpinChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final pinnedChats = prefs.getStringList('pinned_chats') ?? [];
    if (pinnedChats.contains(chatId)) {
      pinnedChats.remove(chatId);
      await prefs.setStringList('pinned_chats', pinnedChats);
    }
  }

  Future<List<String>> getPinnedChats() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('pinned_chats') ?? [];
  }

  Future<Map<String, dynamic>> _loadUserProfileFromCache(String userId) async {
    final db = await DatabaseHelper().database;

    // Получаем профиль из локальной базы данных
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      final profile = maps.first;

      // Преобразуем int в bool (если нужно)
      return {
        ...profile,
        'active': profile['active'] == 1,
        'shshDeveloper': profile['shshDeveloper'] == 1,
        'verifiedEmail': profile['verifiedEmail'] == 1,
        'premium': profile['premium'] == 1,
      };
    }

    return {}; // Возвращаем пустые данные, если профиль не найден
  }

  Future<Map<String, dynamic>> _loadUserProfileFromServer(String userId) async {
    if (!await checkInternetConnection()) {
      return {};
    }

    final response = await _handleRequestWithTokenRefresh(() async {
      final headers = await _getHeaders();
      return await http.get(
        Uri.parse(
            '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final profileData = json.decode(utf8.decode(response.bodyBytes));
      await _saveUserProfile(
          userId, profileData); // Сохраняем новые данные в кеш
      return profileData;
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<void> _saveUserProfile(
      String userId, Map<String, dynamic> profileData) async {
    final db = await DatabaseHelper();

    // Создаем мап профиля с учетом userId как id
    final Map<String, dynamic> profile = {
      'id': userId, // Добавляем userId как id
      ...profileData,
      'active': profileData['active'] == true ? 1 : 0,
      'shshDeveloper': profileData['shshDeveloper'] == true ? 1 : 0,
      'verifiedEmail': profileData['verifiedEmail'] == true ? 1 : 0,
      'premium': profileData['premium'] == true ? 1 : 0,
    };

    // Вставляем профиль в базу данных
    await db.insertProfile(profile);
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

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      onError!('Ошибка авторизации. Пожалуйста, войдите снова.');
      throw CacheException();
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      onError!('Ошибка авторизации. Пожалуйста, войдите снова.');
      throw CacheException();
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      // Обновление токена
      await TokenManager.refreshToken();

      // Повторный запрос с обновленным токеном
      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        onError!('Ошибка авторизации. Пожалуйста, войдите снова.');
        throw CacheException();
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        onError!('Ошибка авторизации. Пожалуйста, войдите снова.');
        throw CacheException();
      }

      response = await request();
    }

    return response;
  }

  Future<Map<String, dynamic>> getUserStatus(String userId) async {
    if (!await checkInternetConnection()) {
      return {};
    }

    final response = await _handleRequestWithTokenRefresh(() async {
      final headers = await _getHeaders();
      return await http.get(
        Uri.parse('${Constants.baseUrl}/ups/api/users/$userId/status'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Пользователь не найден.');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> initializeChatData(Chat chat) async {
    try {
      final userId = await loadUserId();
      final recipientId = chat.user1Id == userId ? chat.user2Id : chat.user1Id;

      final profileData = await _loadUserProfile(recipientId);

      final lastMessage =
          await syncManager.dbHelper.getLastMessageForChat(chat.id);

      return {
        'userId': userId,
        'recipientId': recipientId,
        'profileData': profileData,
        'lastMessage': lastMessage,
      };
    } catch (e) {
      print('Ошибка при инициализации данных чата: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadUserProfile(String userId) async {
    try {
      if (await checkInternetConnection()) {
        return await _loadUserProfileFromServer(userId);
      } else {
        final profileData = await _loadUserProfileFromCache(userId);
        return profileData;
      }
    } catch (e) {
      throw Exception('Ошибка при загрузке профиля пользователя: $e');
    }
  }
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
