import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../models/chat_model.dart';

abstract class MainRemoteDataSource {
  Future<List<ChatModel>> fetchChats(String userId);
  Future<List<ChatModel>> searchUsers(String query);
  Future<ChatModel> createOneToOneChat(String firstUserId, String secondUserId);
  Future<Map<String, dynamic>> getUserProfile(String userId);
  Future<Map<String, dynamic>> getUserProfileForChat(String userId);
}

class MainRemoteDataSourceImpl implements MainRemoteDataSource {
  final http.Client client;

  MainRemoteDataSourceImpl({required this.client});

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

  Future<String> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      return UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
          .id;
    }
    return '';
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

  @override
  Future<List<ChatModel>> fetchChats(String userId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.get(
          Uri.parse(
              '${Constants.baseUrl}${Constants.getAllChatsEndpoint}?userId=$userId'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonList
            .map((json) => ChatModel.fromJson(json as Map<String, dynamic>))
            .where((chat) => chat.id != userId)
            .toList();
      } else {
        throw ServerException('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<ChatModel>> searchUsers(String query) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.get(
          Uri.parse(
              '${Constants.baseUrl}${Constants.searchUsersEndpoint}?query=$query'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        print(json.decode(utf8.decode(response.bodyBytes)));
        return (json.decode(utf8.decode(response.bodyBytes)) as List)
            .map((json) => ChatModel.fromJson2(json))
            .toList();
      } else {
        throw ServerException('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<ChatModel> createOneToOneChat(
      String firstUserId, String secondUserId) async {
    print('firstUserId $firstUserId');
    print('secondUserId $secondUserId');
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.post(
          Uri.parse(
              '${Constants.baseUrl}${Constants.createOneToOneChatEndpoint}'),
          headers: headers,
          body: json.encode({
            'firstUserId': await getCachedUserId(),
            'secondUserId': secondUserId,
          }),
        );
      });

      if (response.statusCode == 200) {
        final chat =
            ChatModel.fromJson2(json.decode(utf8.decode(response.bodyBytes)));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('chatId_$secondUserId', chat.id);
        return chat;
      } else {
        print(response.body);
        throw ServerException('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfileForChat(String userId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.get(
          Uri.parse(
              '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw ServerException('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) {
    // TODO: implement getUserProfile
    throw UnimplementedError();
  }
}
