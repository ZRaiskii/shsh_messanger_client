import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/version_manager.dart';
import '../../auth/data/services/TokenManager.dart';
import '../presentation/pages/outdated_version_page.dart';

class VersionChecker {
  final VersionManager versionManager = VersionManager();
  Timer? _versionCheckTimer;
  bool _isUpdatePageOpen =
      false; // Флаг для отслеживания состояния страницы обновления

  Future<void> checkVersionOnStart(BuildContext context) async {
    var result = {};
    final currentVersion = await getCurrentVersion();
    if (Platform.isAndroid) {
      // result = await versionManager.checkApkVersion(currentVersion, context);
    } else {
      result =
          await versionManager.checkWindowsVersion(currentVersion, context);
    }
    if (result["code"] == "201") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Версия приложения устарела, пожалуйства обновите её!')),
      );
    }
    if (result["code"] == "400" && !_isUpdatePageOpen) {
      _isUpdatePageOpen = true; // Устанавливаем флаг, что страница открыта
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => OutdatedVersionPage(
            errorMessage:
                "Установленная версия больше не используется, необходимо обновить!",
            platform: Platform.isAndroid ? "android" : "windows",
          ),
        ),
        (route) => false, // Закрываем все предыдущие страницы
      );
    }
  }

  void startVersionCheckTimer(BuildContext context) {
    _versionCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      final currentVersion = await getCurrentVersion();
      final result =
          await versionManager.checkApkVersion(currentVersion, context);

      if (result["code"] == "404" && !_isUpdatePageOpen) {
        _isUpdatePageOpen = true; // Устанавливаем флаг, что страница открыта
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OutdatedVersionPage(
              errorMessage:
                  "Установленная версия устарела, необходимо обновить!",
              platform: Platform.isAndroid ? "android" : "windows",
            ),
          ),
          (route) => false, // Закрываем все предыдущие страницы
        );
      }
    });
  }

  static String getCurrentVersion() {
    return "0.4.0";
  }

  void stopVersionCheckTimer() {
    _versionCheckTimer?.cancel();
  }
}
