import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../version/domain/version_checker.dart';
import '../../../../core/utils/AppColors.dart';
import 'package:provider/provider.dart';
import '../../../../core/DownloadProgressProvider.dart';
import '../../data/services/theme_manager.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? _token;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getToken();
    _getUserId();
  }

  Future<void> _getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _token = token;
      });
    } catch (e) {
      print("Ошибка при получении токена: $e");
    }
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      final userId =
          UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
              .id;
      setState(() {
        _userId = userId;
      });
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Скопировано в буфер обмена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page', style: TextStyle(color: colors.textColor)),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User ID:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _userId ?? 'Загрузка...',
              style: TextStyle(
                fontSize: 16,
                color: colors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(_userId ?? ''),
              icon: Icon(Icons.copy, color: colors.iconColor),
              label: Text(
                'Копировать ID',
                style: TextStyle(fontSize: 16, color: colors.textColor),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: colors.appBarColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FCM Token:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _token ?? 'Загрузка...',
              style: TextStyle(
                fontSize: 16,
                color: colors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(_token ?? ''),
              icon: Icon(Icons.copy, color: colors.iconColor),
              label: Text(
                'Копировать токен',
                style: TextStyle(fontSize: 16, color: colors.textColor),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: colors.appBarColor,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: colors.backgroundColor,
    );
  }
}
