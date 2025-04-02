import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import '../../features/version/domain/version_checker.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/services/TokenManager.dart';
import '../error/exceptions.dart';
import 'KeysManager.dart';

class DeviceRegistration {
  static const String _baseUrl = Constants.baseUrl;

  static Future<String> getDeviceId() async {
    String? deviceId;

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('device_id');
    } else {
      deviceId = await KeysManager.read('device_id');
    }

    if (deviceId == null) {
      deviceId = const Uuid().v4();

      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_id', deviceId);
      } else {
        await KeysManager.write('device_id', deviceId);
      }
    }

    return deviceId;
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    var huawei = "";
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      final status = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      if (!(status == GooglePlayServicesAvailability.success)) {
        huawei = ".huawei";
      }
      return {
        'platform': 'android$huawei',
        'deviceModel': androidInfo.model,
        'osVersion': androidInfo.version.release,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'deviceModel': iosInfo.name,
        'osVersion': iosInfo.systemVersion,
      };
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return {
        'platform': 'windows',
        'deviceModel': windowsInfo.computerName,
        'osVersion': windowsInfo.majorVersion.toString() +
            '.' +
            windowsInfo.minorVersion.toString() +
            '.' +
            windowsInfo.buildNumber.toString(),
      };
    } else {
      return {
        'platform': 'unknown',
        'deviceModel': 'Unknown Device',
        'osVersion': 'Unknown OS',
      };
    }
  }

  static Future<void> registerDevice(String userId) async {
    final deviceRegistared = await KeysManager.read("device_registered");
    print("deviceRegistared: $deviceRegistared");
    if (deviceRegistared == null) {
      try {
        final deviceId = await getDeviceId();

        String? pushToken;
        if (Platform.isAndroid || Platform.isIOS) {
          pushToken = await FirebaseMessaging.instance.getToken();
        } else if (Platform.isWindows) {
          pushToken = "";
        }

        final deviceInfo = await getDeviceInfo();

        final appVersion = await getAppVersion();

        final requestBody = {
          "userId": userId,
          "deviceId": deviceId,
          "pushToken": pushToken,
          "platform": deviceInfo['platform'],
          "deviceModel": deviceInfo['deviceModel'],
          "osVersion": deviceInfo['osVersion'],
          "appVersion": appVersion,
        };
        print("requestBody: $requestBody");
        final response = await _handleRequestWithTokenRefresh(() async {
          final headers = await _getHeaders();
          return await http.post(
            Uri.parse('${Constants.baseUrl}/notifications/register-device'),
            headers: headers,
            body: jsonEncode(requestBody),
          );
        });
        print("register device response: ${response.body}");
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success']) {
            print('Устройство успешно зарегистрировано.');
            KeysManager.write('device_registered', "1");
          } else {
            throw Exception(
                'Ошибка регистрации устройства: ${responseData['message']}');
          }
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        print('Ошибка при регистрации устройства: $e');
      }
    }
  }

  static Future<int> unregisterDevice(String userId) async {
    var code = 0;
    try {
      final deviceId = await getDeviceId();
      final requestBody = {
        "deviceId": deviceId,
        "userId": userId,
      };

      print("Unregistering device with request: $requestBody");

      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await http.delete(
          Uri.parse('${Constants.baseUrl}/notifications/unregister-device'),
          headers: headers,
          body: jsonEncode(requestBody),
        );
      });

      print("Unregister device response: ${response.body}");

      if (response.statusCode == 204) {
        // Успешно отвязано устройство
        print('Устройство успешно отвязано.');
        if (Platform.isAndroid) {
          await KeysManager.delete(
              'device_registered'); // Очищаем флаг регистрации
        }
      } else if (response.statusCode == 400) {
        // Некорректные параметры запроса
        final responseData = json.decode(response.body);
        throw Exception('Ошибка: ${responseData['message']}');
      } else if (response.statusCode == 404) {
        // Устройство не найдено
        final responseData = json.decode(response.body);
        throw Exception('Ошибка: ${responseData['message']}');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
      return response.statusCode;
    } catch (e) {
      print('Ошибка при отвязке устройства: $e');
    }
    return code;
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser != null) {
        final userId =
            UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
                .id;

        // Отвязываем устройство
        await unregisterDevice(userId);

        // Очищаем данные пользователя
        await prefs.remove('cached_user');

        print('Пользователь успешно вышел из системы.');
      } else {
        print('Нет данных пользователя для выхода.');
      }
    } catch (e) {
      print('Ошибка при выходе из системы: $e');
      rethrow; // Передаем ошибку дальше, если это необходимо
    }
  }

  static Future<String> getAppVersion() async {
    return VersionChecker.getCurrentVersion();
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      final token =
          UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
              .token;
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      throw ServerException('Token not available');
    }
  }

  static Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw CacheException();
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw CacheException();
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      // Обновление токена
      await TokenManager.refreshToken();

      // Повторный запрос с обновленным токеном
      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw CacheException();
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw CacheException();
      }

      response = await request();
    }

    return response;
  }
}
