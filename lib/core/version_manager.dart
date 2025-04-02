import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/auth/data/services/TokenManager.dart';
import '../features/version/presentation/pages/outdated_version_page.dart';
import 'DownloadProgressProvider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionManager {
  static final VersionManager _instance = VersionManager._internal();
  static String? _savePath;

  factory VersionManager() {
    return _instance;
  }

  VersionManager._internal();

  static final ValueNotifier<int> downloadProgress = ValueNotifier<int>(0);
  final String _baseUrl = 'http://90.156.171.188:5000';

  String get _platform {
    if (kIsWeb) {
      return "web";
    } else if (Platform.isAndroid) {
      return "android";
    } else if (Platform.isIOS) {
      return "ios";
    } else if (Platform.isWindows) {
      return "windows";
    } else if (Platform.isLinux) {
      return "linux";
    } else if (Platform.isMacOS) {
      return "macos";
    } else {
      return "unknown";
    }
  }

  Future<Map<String, dynamic>> checkApkVersion(
      String currentVersion, BuildContext context) async {
    try {
      if (!await _checkInternetConnection()) {
        return {
          "code": "0",
          "error":
              "Нет доступа к интернету. Пожалуйста, проверьте подключение.",
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/check_apk_version/$currentVersion'),
      );

      switch (response.statusCode) {
        case 200:
          return {
            "code": "${response.statusCode}",
            "message": "Версия APK актуальна",
            "data": json.decode(response.body),
          };
        case 400:
          return {
            "code": "${response.statusCode}",
            "error":
                "Версия $currentVersion не является последней активной. Рекомендуем обновить приложение!",
          };
        case 201:
          return {
            "code": "${response.statusCode}",
            "error":
                "Версия $currentVersion не является последней активной. Рекомендуем обновить приложение!",
          };
        case 404:
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OutdatedVersionPage(
                errorMessage:
                    "Установленная версия устарела, необходимо обновить!",
                platform: _platform,
              ),
            ),
          );
          return {
            "code": "${response.statusCode}",
            "error": "Установленная версия устарела, необходимо обновить!",
          };
        case 500:
          return {
            "code": "${response.statusCode}",
            "error": "Ошибка сервера: ${response.body}",
          };
        default:
          throw Exception("Неизвестный статус код: ${response.statusCode}");
      }
    } catch (e) {
      return {};
      // throw Exception('Ошибка при проверке версии APK: $e');
    }
  }

  Future<Map<String, dynamic>> checkWindowsVersion(
      String currentVersion, BuildContext context) async {
    try {
      if (!await _checkInternetConnection()) {
        return {
          "code": "0",
          "error":
              "Нет доступа к интернету. Пожалуйста, проверьте подключение.",
        };
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/api/check_windows_version/$currentVersion'),
      );

      print(response.body);
      switch (response.statusCode) {
        case 200:
          return {
            "code": "${response.statusCode}",
            "message": "Версия Windows-установщика актуальна",
            "data": json.decode(response.body),
          };
        case 400:
          return {
            "code": "${response.statusCode}",
            "error":
                "Версия $currentVersion не является последней активной. Рекомендуем обновить приложение!",
          };
        case 404:
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OutdatedVersionPage(
                errorMessage:
                    "Установленная версия устарела, необходимо обновить!",
                platform: _platform,
              ),
            ),
          );
          return {
            "code": "${response.statusCode}",
            "error": "Установленная версия устарела, необходимо обновить!",
          };
        case 500:
          return {
            "code": "${response.statusCode}",
            "error": "Ошибка сервера: ${response.body}",
          };
        default:
          return {};
      }
    } catch (e) {
      throw Exception('Ошибка при проверке версии Windows-установщика: $e');
    }
  }

  Future<void> downloadAndInstallApk(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appId = packageInfo.packageName;

      final storeUrls = [
        // 'market://details?id=$appId', // Google Play
        'rst://app_details?package=$appId', // RuStore
        // 'appmarket://details?id=$appId', // AppGallery
      ];

      for (var url in storeUrls) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          return;
        }
      }

      final webUrl = 'https://play.google.com/store/apps/details?id=$appId';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        throw Exception('Не удалось найти подходящий магазин приложений');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  static Future<void> _installApk(String filePath, BuildContext context) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Файл пустой: $filePath');
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Не удалось открыть файл: ${result.message}');
      }
    } catch (e) {
      print(e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при установке APK: $e')),
        );
      }
    }
  }

  Future<void> downloadWindowsInstaller(BuildContext context) async {
    try {
      if (!await _checkInternetConnection()) {
        return;
      }

      final String url =
          'http://90.156.171.188:5000/download/latest_windows_installer';
      final String fileName = 'latest_installer.exe';

      final directory = await getDownloadsDirectory();
      _savePath = '${directory?.path}/$fileName';

      downloadProgress.value = 0;

      final dio = Dio();
      await dio.download(
        url,
        _savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            downloadProgress.value = progress;
            if (context.mounted) {
              final progressProvider =
                  Provider.of<DownloadProgressProvider>(context, listen: false);
              progressProvider.updateProgress(progress);
            }
          }
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Загрузка завершена')),
        );
      }

      await _openFileWin(_savePath!, context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка при загрузке Windows-установщика: $e')),
        );
      }
    }
  }

  static Future<void> _openFileWin(
      String filePath, BuildContext context) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Файл пустой: $filePath');
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Не удалось открыть файл: ${result.message}');
      }
    } catch (e) {
      print(e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при открытии файла: $e')),
        );
      }
    }
  }

  Future<bool> _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await _isScopedStorageEnabled()) {
        print("Устройство использует Scoped Storage (Android 10+).");
        final manageExternalStorageStatus =
            await Permission.manageExternalStorage.request();
        print(
            "Статус разрешения MANAGE_EXTERNAL_STORAGE: $manageExternalStorageStatus");
        if (!manageExternalStorageStatus.isGranted) {
          print("Разрешение MANAGE_EXTERNAL_STORAGE не предоставлено.");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Разрешение на доступ к внешнему хранилищу не предоставлено.'),
              ),
            );
          }
          return false;
        }
      } else {
        print(
            "Устройство использует старую систему разрешений (Android 9 и ниже).");
        final storageStatus = await Permission.storage.request();
        print("Статус разрешения STORAGE: $storageStatus");
        if (!storageStatus.isGranted) {
          print("Разрешение STORAGE не предоставлено.");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Разрешение на доступ к хранилищу не предоставлено.'),
              ),
            );
          }
          return false;
        }
      }

      final installStatus = await Permission.requestInstallPackages.request();
      print("Статус разрешения REQUEST_INSTALL_PACKAGES: $installStatus");
      if (!installStatus.isGranted) {
        print("Разрешение REQUEST_INSTALL_PACKAGES не предоставлено.");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Разрешение на установку из неизвестных источников не предоставлено.'),
            ),
          );
        }
        return false;
      }

      return true;
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  Future<bool> _isScopedStorageEnabled() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      print(androidInfo.version.sdkInt);
      return androidInfo.version.sdkInt > 29; // Android 10 и выше
    }
    return false;
  }

  Future<Directory?> _getDownloadDirectory() async {
    if (await _isScopedStorageEnabled()) {
      // Для Android 10 и выше используем Scoped Storage
      return await getExternalStorageDirectory();
    } else {
      // Для Android 9 и ниже используем традиционный метод
      return await getExternalStorageDirectory();
    }
  }

  Future<bool> _checkInternetConnection() async {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
}
