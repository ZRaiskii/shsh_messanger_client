import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/AppColors.dart';
import '../../data/services/theme_manager.dart';

class NotificationsSettingsPage extends StatefulWidget {
  @override
  _NotificationsSettingsPageState createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _inAppNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showMessageCounter = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _inAppNotifications = prefs.getBool('in_app_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _showMessageCounter = prefs.getBool('show_message_counter') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('in_app_notifications', _inAppNotifications);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('show_message_counter', _showMessageCounter);
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title: Text('Уведомления и звуки',
            style: TextStyle(color: colors.textColor)),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Блок "В приложении"
          Card(
            color: colors.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Подпись блока
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'В приложении',
                    style: TextStyle(
                      fontSize: 14, // Маленький размер шрифта
                      color: colors.textColor
                          .withOpacity(0.7), // Полупрозрачный цвет
                    ),
                  ),
                ),
                // Настройки
                ListTile(
                  title: Text('Показывать уведомления',
                      style: TextStyle(color: colors.textColor)),
                  trailing: Switch(
                    value: _inAppNotifications,
                    onChanged: (value) {
                      setState(() {
                        _inAppNotifications = value;
                        _saveSettings();
                      });
                    },
                  ),
                ),
                ListTile(
                  title:
                      Text('Звук', style: TextStyle(color: colors.textColor)),
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                        _saveSettings();
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text('Вибросигнал',
                      style: TextStyle(color: colors.textColor)),
                  trailing: Switch(
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _vibrationEnabled = value;
                        _saveSettings();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Подсказка между блоками
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Настройки уведомлений, звука и вибрации внутри приложения.',
              style: TextStyle(
                color: colors.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Блок "Счётчик сообщений"
          Card(
            color: colors.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Подпись блока
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Счётчик сообщений',
                    style: TextStyle(
                      fontSize: 14, // Маленький размер шрифта
                      color: colors.textColor
                          .withOpacity(0.7), // Полупрозрачный цвет
                    ),
                  ),
                ),
                // Настройки
                ListTile(
                  title: Text('Показывать счётчик',
                      style: TextStyle(color: colors.textColor)),
                  trailing: Switch(
                    value: _showMessageCounter,
                    onChanged: (value) {
                      setState(() {
                        _showMessageCounter = value;
                        _saveSettings();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Подсказка между блоками
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Показывать количество непрочитанных сообщений.',
              style: TextStyle(
                color: colors.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundColor,
    );
  }
}
