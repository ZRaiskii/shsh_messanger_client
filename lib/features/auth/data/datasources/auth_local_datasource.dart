// lib/features/auth/data/datasources/auth_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getUser();
  Future<void> cacheUser(UserModel userToCache);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl();

  @override
  Future<UserModel> getUser() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final jsonString = sharedPreferences.getString('cached_user');
    if (jsonString != null) {
      print('Cached user JSON: $jsonString'); // Логирование кэшированного JSON
      return Future.value(UserModel.fromJson(json.decode(jsonString)));
    } else {
      throw CacheException();
    }
  }

  @override
  Future<Future<bool>> cacheUser(UserModel userToCache) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.setString(
      'cached_user',
      json.encode(userToCache.toJson()),
    );
  }
}
