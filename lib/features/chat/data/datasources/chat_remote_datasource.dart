import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../main/data/services/data_manager.dart';
import '../../domain/entities/message.dart';
import '../services/stomp_client.dart';

abstract class ChatRemoteDataSource {
  Future<List<Message>> fetchMessages(String chatId);
  Future<void> sendMessage(String chatId, String recipientId, String content);
  Future<void> sendPhotoMessage(
      String chatId, String recipientId, String photoUrl);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client client;
  final WebSocketClientService webSocketClientService;

  ChatRemoteDataSourceImpl({
    required this.client,
    required this.webSocketClientService,
  });

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
      await TokenManager.refreshToken();

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

  @override
  Future<List<Message>> fetchMessages(String chatId) async {
    try {
      final _datamanager = DataManager();

      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser == null) {
        throw CacheException();
      }

      final userId =
          UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
              .id;

      _datamanager.syncManager.syncChatsWithServer(userId);
      final cachedMessages =
          await _datamanager.syncManager.dbHelper.getMessages(chatId);

      return cachedMessages;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> sendMessage(
      String chatId, String recipientId, String content) async {
    webSocketClientService.sendMessage(recipientId, chatId, content);
  }

  @override
  Future<void> sendPhotoMessage(
      String chatId, String recipientId, String photoUrl) async {
    webSocketClientService.sendPhotoMessage(recipientId, chatId, photoUrl);
  }
}
