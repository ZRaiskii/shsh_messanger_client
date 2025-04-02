import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/constants.dart';
import '../models/user_model.dart';
import '../../presentation/pages/auth_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TokenManager {
  static Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');

    if (cachedUser == null) {
      throw Exception('Cached user is missing');
    }

    final userMap = json.decode(cachedUser) as Map<String, dynamic>;
    final userModel = UserModel.fromJson(userMap);
    final refreshToken = userModel.refreshToken;

    if (refreshToken.isEmpty) {
      throw Exception('Refresh token is missing');
    }

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final newAccessToken = responseBody['token'];
      final newRefreshToken = responseBody['refreshToken'];

      final updatedUserModel = UserModel(
        id: userModel.id,
        email: userModel.email,
        username: userModel.username,
        token: newAccessToken,
        refreshToken: newRefreshToken,
      );

      await prefs.setString(
          'cached_user', json.encode(updatedUserModel.toJson()));

      print('Tokens successfully refreshed');
    } else if (response.statusCode == 401) {
      await clearCache();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      final errorResponse = json.decode(response.body);
      throw Exception('Failed to refresh token: ${errorResponse['message']}');
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
