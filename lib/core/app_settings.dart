import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static int animRate = 5;

  // Настройки сообщений
  static double messageTextSize = 16.0;
  static double messageCornerRadius = 8.0;

  // Настройки внешнего вида
  static String wallpaper = '';
  static String chatListType = 'two_line';
  static String selectedAnimation = 'none';

  // Настройки свайпов
  static String swipeAction = 'Нет';

  // Настройки уведомлений
  static bool inAppNotifications = true;
  static bool soundEnabled = true;
  static bool vibrationEnabled = true;
  static bool showMessageCounter = true;

  // Метод для загрузки всех настроек
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Загружаем настройки сообщений
    messageTextSize = prefs.getDouble('message_text_size') ?? 16.0;
    messageCornerRadius = prefs.getDouble('message_corner_radius') ?? 8.0;

    // Загружаем настройки внешнего вида
    wallpaper = prefs.getString('wallpaper') ?? '';
    chatListType = prefs.getString('chat_list_type') ?? 'two_line';
    selectedAnimation = prefs.getString('selected_animation') ?? 'none';

    // Загружаем настройки свайпов
    swipeAction = prefs.getString('swipe_action') ?? 'archive';

    // Загружаем настройки уведомлений
    inAppNotifications = prefs.getBool('in_app_notifications') ?? true;
    soundEnabled = prefs.getBool('sound_enabled') ?? true;
    vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    showMessageCounter = prefs.getBool('show_message_counter') ?? true;
  }

  // Метод для сохранения всех настроек (опционально)
  static Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Сохраняем настройки сообщений
    await prefs.setDouble('message_text_size', messageTextSize);
    await prefs.setDouble('message_corner_radius', messageCornerRadius);

    // Сохраняем настройки внешнего вида
    await prefs.setString('wallpaper', wallpaper);
    await prefs.setString('chat_list_type', chatListType);
    await prefs.setString('selected_animation', selectedAnimation);

    // Сохраняем настройки свайпов
    await prefs.setString('swipe_action', swipeAction);

    // Сохраняем настройки уведомлений
    await prefs.setBool('in_app_notifications', inAppNotifications);
    await prefs.setBool('sound_enabled', soundEnabled);
    await prefs.setBool('vibration_enabled', vibrationEnabled);
    await prefs.setBool('show_message_counter', showMessageCounter);
  }
}
