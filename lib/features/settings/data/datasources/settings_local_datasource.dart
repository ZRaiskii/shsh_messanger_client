// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/features/settings/data/models/settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsModel> getCachedSettings();
  Future<void> cacheSettings(SettingsModel settingsToCache);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<SettingsModel> getCachedSettings() async {
    final jsonString = sharedPreferences.getString('cached_settings');
    print('getCachedSettings: jsonString = $jsonString'); // Логирование
    if (jsonString != null) {
      return Future.value(SettingsModel.fromJson(json.decode(jsonString)));
    } else {
      // Use default values if no cached settings are found
      return Future.value(SettingsModel(
        language: 'English',
        notificationsEnabled: true,
        snowflakesEnabled: true,
        messageTextSize: 16.0,
        wallpaper: 'default',
        chatListType: 'two_line',
      ));
    }
  }

  @override
  Future<void> cacheSettings(SettingsModel settingsToCache) async {
    final jsonString = json.encode(settingsToCache.toJson());
    print('cacheSettings: jsonString = $jsonString'); // Логирование
    await sharedPreferences.setString('cached_settings', jsonString);
  }
}
