// lib/features/chat/data/datasources/chat_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';

abstract class ChatLocalDataSource {
  Future<void> cacheMessages(List<Message> messages);
  Future<List<MessageModel>> getCachedMessages();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final SharedPreferences sharedPreferences;

  ChatLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<MessageModel>> getCachedMessages() {
    final jsonString = sharedPreferences.getString('cached_messages');
    if (jsonString != null) {
      return Future.value(
        (json.decode(jsonString) as List)
            .map((json) => MessageModel.fromJson(json))
            .toList(),
      );
    } else {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheMessages(List<Message> messagesToCache) {
    final List<Map<String, dynamic>> jsonList =
        messagesToCache.map((message) => message.toJson()).toList();
    return sharedPreferences.setString(
      'cached_messages',
      json.encode(jsonList),
    );
  }
}
