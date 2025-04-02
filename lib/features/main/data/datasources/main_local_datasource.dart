import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/chat_model.dart';

abstract class MainLocalDataSource {
  Future<List<ChatModel>> getCachedChats();
  Future<void> cacheChats(List<ChatModel> chatsToCache);
}

class MainLocalDataSourceImpl implements MainLocalDataSource {
  final SharedPreferences sharedPreferences;

  MainLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<ChatModel>> getCachedChats() async {
    try {
      final jsonString = sharedPreferences.getString('cached_chats');
      if (jsonString != null) {
        return (json.decode(jsonString) as List)
            .map((json) => ChatModel.fromJson(json))
            .toList();
      } else {
        throw CacheException('Кэшированные чаты не найдены.');
      }
    } catch (e) {
      print(
          'MainLocalDataSourceImpl getCachedChats Ошибка: $e'); // Логирование ошибки
      throw CacheException('Ошибка кэша: $e');
    }
  }

  @override
  Future<void> cacheChats(List<ChatModel> chatsToCache) async {
    try {
      final List<Map<String, dynamic>> jsonList =
          chatsToCache.map((chat) => chat.toJson()).toList();
      final bool success = await sharedPreferences.setString(
        'cached_chats',
        json.encode(jsonList),
      );
      if (!success) {
        throw CacheException('Не удалось сохранить чаты в кэш.');
      }
    } catch (e) {
      print(
          'MainLocalDataSourceImpl cacheChats Ошибка: $e'); // Логирование ошибки
      throw CacheException('Ошибка сохранения кэша: $e');
    }
  }
}
