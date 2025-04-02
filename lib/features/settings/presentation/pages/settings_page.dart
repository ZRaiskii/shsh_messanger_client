import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../../core/utils/KeysManager.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../../data/services/theme_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

import '../../../../core/data_base_helper.dart';
import '../../../../core/utils/AppColors.dart';
import 'about_app_page.dart';
import 'chat_settings_page.dart';
import 'data_settings_page.dart';
import 'notification_settings_page.dart';
import 'premium_page.dart';

class SettingsPage extends StatelessWidget {
  void _showNotImplementedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ещё не реализовано'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<int> logout(String userId, String deviceId) async {
    final url = Uri.parse('${Constants.baseUrl}/auth/logout');
    final headers = await _getHeaders();
    final body = json.encode({
      'userId': userId,
      'deviceId': deviceId,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print('Logout successful');
    } else if (response.statusCode == 400) {
      print('Invalid request: ${response.body}');
    } else if (response.statusCode == 500) {
      print('Server error: ${response.body}');
    } else {
      print('Failed to logout: ${response.body}');
    }
    return response.statusCode;
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
      throw Exception('Token not available');
    }
  }

  Future<String> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      try {
        final userMap = json.decode(cachedUser) as Map<String, dynamic>;
        final userId = UserModel.fromJson(userMap).id;
        return userId;
      } catch (e) {
        throw Exception('Error loading user ID: $e');
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isWhiteNotifier,
      builder: (context, isWhite, child) {
        final colors = isWhite ? AppColors.light() : AppColors.dark();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Настройки',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            backgroundColor: colors.appBarColor,
            iconTheme: IconThemeData(color: colors.iconColor),
            actions: [
              IconButton(
                icon: Icon(Icons.bug_report, color: colors.iconColor),
                onPressed: () {
                  _launchURL();
                },
              ),
              IconButton(
                icon: Icon(isWhite ? Icons.wb_sunny : Icons.nights_stay,
                    color: colors.iconColor),
                onPressed: () async {
                  bool newTheme = !isWhiteNotifier.value;
                  await ThemeManager.setTheme(newTheme);
                  isWhiteNotifier.value = newTheme;
                  // Navigator.of(context).popAndPushNamed('/main');
                },
              ),
              IconButton(
                icon: Icon(Icons.logout, color: colors.iconColor),
                onPressed: () async {
                  final colors = isWhiteNotifier.value
                      ? AppColors.light()
                      : AppColors.dark();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: colors.cardColor,
                        title: Text(
                          'Подтверждение выхода',
                          style: TextStyle(color: colors.textColor),
                        ),
                        content: Text(
                          'Вы уверены, что хотите выйти? Кеш будет очищен.',
                          style: TextStyle(color: colors.textColor),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text(
                              'Отмена',
                              style: TextStyle(color: colors.primaryColor),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(); // Закрываем диалог
                            },
                          ),
                          TextButton(
                            child: Text(
                              'Выйти',
                              style: TextStyle(color: colors.primaryColor),
                            ),
                            onPressed: () async {
                              Navigator.of(context)
                                  .pop(); // Закрываем текущий диалог

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final userId = await loadUserId();
                              final deviceId =
                                  await KeysManager.read('device_id');

                              try {
                                final code = await logout(userId!, deviceId!);

                                if (code == 200) {
                                  DatabaseHelper().clearDatabase();
                                  await prefs.clear();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Произошла ошибка при выходе!'),
                                      duration: Duration(milliseconds: 1500),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print(e);
                              }
                              navigatorKey.currentState?.pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => AuthPage()),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 16.0), // Отступ сверху
            children: [
              // Основные настройки
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: colors.cardColor, // Фон чуть светлее основного
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.chat, color: colors.iconColor),
                      title: Text('Настройки чатов',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatSettingsPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.security, color: colors.iconColor),
                      title: Text('Конфиденциальность',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        _showNotImplementedMessage(context);
                      },
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.notifications, color: colors.iconColor),
                      title: Text('Уведомления и звуки',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NotificationsSettingsPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.storage, color: colors.iconColor),
                      title: Text('Данные и память',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DataSettingsPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.battery_charging_full,
                          color: colors.iconColor),
                      title: Text('Энергосбережение',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        _showNotImplementedMessage(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.language, color: colors.iconColor),
                      title: Text('Язык',
                          style: TextStyle(color: colors.textColor)),
                      trailing: Text(
                        'Русский',
                        style: TextStyle(
                          color: Colors.lightBlue, // Светло-синий цвет
                          fontSize: 16, // Размер текста
                        ),
                      ),
                      onTap: () {
                        _showNotImplementedMessage(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.info, color: colors.iconColor),
                      title: Text('О приложении',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AboutAppPage()),
                        );
                      },
                    ),
                    // ListTile(
                    //   leading: Icon(Icons.info, color: colors.iconColor),
                    //   title: Text('Admin Test',
                    //       style: TextStyle(color: colors.textColor)),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => AdminPage()),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
              // Блок с "ЩЩ Premium" и "Отправить подарок"
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: colors.cardColor, // Фон чуть светлее основного
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.star, color: colors.iconColor),
                      title: Text('ЩЩ Premium',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PremiumPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.card_giftcard, color: colors.iconColor),
                      title: Text('Отправить подарок',
                          style: TextStyle(color: colors.textColor)),
                      onTap: () {
                        _showNotImplementedMessage(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // _buildSupportAuthorsButton(context, colors),
              // const SizedBox(height: 25),
            ],
          ),
          backgroundColor: colors.backgroundColor,
        );
      },
    );
  }

  Widget _buildSupportAuthorsButton(BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        onPressed: () async {
          launchUrlString('https://www.tbank.ru/cf/48e4IFH1Xm0');
        },
        icon: Icon(Icons.favorite, color: Colors.red),
        label: Text(
          'Поддержать авторов',
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
    );
  }
}

Future<void> _launchURL() async {
  const url = 'https://forms.yandex.ru/u/677d0b5502848f3b397e91a9/';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Не удалось открыть ссылку: $url';
  }
}
