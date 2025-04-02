// lib/features/settings/data/repositories/settings_repository_impl.dart
import 'package:shsh_social/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:shsh_social/features/settings/data/models/settings_model.dart'
    as model;
import 'package:shsh_social/features/settings/domain/entities/settings.dart';
import 'package:shsh_social/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Settings> fetchSettings() async {
    final localSettings = await localDataSource.getCachedSettings();
    print(
        'fetchSettings: localSettings = ${localSettings.toJson()}'); // Логирование
    return Settings(
      language: localSettings.language,
      notificationsEnabled: localSettings.notificationsEnabled,
      snowflakesEnabled: localSettings.snowflakesEnabled,
      messageTextSize: localSettings.messageTextSize,
      wallpaper: localSettings.wallpaper,
      chatListType: localSettings.chatListType,
    );
  }

  @override
  Future<void> updateSettings(Settings settings) async {
    final settingsModel = model.SettingsModel(
      language: settings.language,
      notificationsEnabled: settings.notificationsEnabled,
      snowflakesEnabled: settings.snowflakesEnabled,
      messageTextSize: settings.messageTextSize,
      wallpaper: settings.wallpaper,
      chatListType: settings.chatListType,
    );
    print(
        'updateSettings: settingsModel = ${settingsModel.toJson()}'); // Логирование
    await localDataSource.cacheSettings(settingsModel);
  }
}
