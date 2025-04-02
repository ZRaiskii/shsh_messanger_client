import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const String _keyTheme = 'isWhite';

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? true;
  }

  static Future<void> setTheme(bool isWhite) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, isWhite);
  }
}

final ValueNotifier<bool> isWhiteNotifier = ValueNotifier<bool>(true);
