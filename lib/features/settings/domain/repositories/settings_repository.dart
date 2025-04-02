// lib/features/settings/domain/repositories/settings_repository.dart
import 'package:shsh_social/features/settings/domain/entities/settings.dart';

abstract class SettingsRepository {
  Future<Settings> fetchSettings();
  Future<void> updateSettings(Settings settings);
}
