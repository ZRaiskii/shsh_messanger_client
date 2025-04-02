// lib/features/settings/data/services/settings_service.dart
import 'package:shsh_social/features/settings/domain/entities/settings.dart';
import 'package:shsh_social/features/settings/domain/repositories/settings_repository.dart';

class SettingsService {
  final SettingsRepository repository;

  SettingsService(this.repository);

  Future<Settings> fetchSettings() {
    return repository.fetchSettings();
  }

  Future<void> updateSettings(Settings settings) {
    return repository.updateSettings(settings);
  }
}
