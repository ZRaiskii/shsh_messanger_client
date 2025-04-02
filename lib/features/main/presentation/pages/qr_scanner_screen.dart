import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../data/services/data_manager.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  String? _extractUserIdFromQRCode(String qrCode) {
    final RegExp regex = RegExp(r'^\{::\((.+)\)/openChat\}$');
    final match = regex.firstMatch(qrCode);
    if (match != null && match.groupCount >= 1) {
      return match.group(1); // Возвращаем userId
    }
    return null; // Если формат не совпадает
  }

  void _handleQRCodeResult(BuildContext context, String result) async {
    final userId = _extractUserIdFromQRCode(result);

    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('cached_user');

      if (cachedUser != null) {
        try {
          final userMap = json.decode(cachedUser) as Map<String, dynamic>;
          final currentUserId = UserModel.fromJson(userMap).id;

          if (currentUserId != null) {
            // Получаем все чаты с сервера
            final dataManager = DataManager();
            final chats = await dataManager.getChats(currentUserId);

            // Ищем чат с нужным recipientId
            final chat = chats.firstWhereOrNull(
              (chat) => chat.user1Id == userId || chat.user2Id == userId,
            );

            if (chat != null) {
              _openChatPage(context, chat.id, userId);
            } else {
              // Если чат не найден, создаем новый чат
              _openChatPage(context, null, userId);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Ошибка: текущий пользователь не найден')),
            );
          }
        } catch (e) {
          print('Ошибка при декодировании пользователя: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Упс...')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ошибка: данные пользователя не найдены')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный формат QR-Code')),
      );
    }
  }

  void _openChatPage(
      BuildContext context, String? chatId, String recipientId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      try {
        final userMap = json.decode(cachedUser) as Map<String, dynamic>;
        final userId = UserModel.fromJson(userMap).id;
        if (userId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                chatId: chatId,
                userId: userId,
                recipientId: recipientId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Упс...')),
          );
        }
      } catch (e) {
        print('Ошибка при декодировании пользователя: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Упс...')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Упс...')),
      );
    }
  }

  Future<Map<String, String>> _getHeaders() async {
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
      throw Exception('Токен недоступен');
    }
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw Exception('Пользователь не найден в кэше');
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw Exception('Токен пуст');
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      // Обновление токена
      await TokenManager.refreshToken();

      // Повторный запрос с обновленным токеном
      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw Exception(
            'Пользователь не найден в кэше после обновления токена');
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw Exception('Токен пуст после обновления');
      }

      response = await request();
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: MobileScanner(
        controller: _cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first;
            final result = barcode.rawValue;

            if (result != null) {
              _handleQRCodeResult(context, result);
            }
          }
        },
      ),
    );
  }
}
