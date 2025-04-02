import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../version/domain/version_checker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/utils/AppColors.dart';
import '../../data/services/theme_manager.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import '../../../../core/DownloadProgressProvider.dart';
import '../../../../core/version_manager.dart';

class AboutAppPage extends StatelessWidget {
  final VersionManager versionManager = VersionManager();

  String get _platform {
    if (Platform.isAndroid) {
      return "android";
    } else if (Platform.isWindows) {
      return "windows";
    } else {
      return "unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title: Text('О приложении', style: TextStyle(color: colors.textColor)),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Логотип приложения с закруглёнными углами
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0), // Закругление углов
              child: Image.asset(
                'assets/icons/icon.png', // Путь к иконке
                width: 100, // Ширина изображения
                height: 100, // Высота изображения
                fit: BoxFit.cover, // Чтобы изображение заполнило область
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Название приложения
          Center(
            child: Text(
              'ЩЩ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Версия приложения
          Center(
            child: Text(
              'Версия ${VersionChecker.getCurrentVersion()}',
              style: TextStyle(
                fontSize: 16,
                color: colors.textColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Информация о разработчиках
          Card(
            color: colors.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Разработчики',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Команда SHSH Inc',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Свяжитесь с нами: SHSH.Inc@yandex.ru',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Блок "Обновление приложения"
          Card(
            color: colors.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Обновление приложения',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<DownloadProgressProvider>(
                    builder: (context, progressProvider, child) {
                      if (progressProvider.progress > 0) {
                        // Если загрузка идёт, покажем прогресс
                        return Column(
                          children: [
                            ListTile(
                              leading:
                                  Icon(Icons.download, color: colors.iconColor),
                              title: Text(
                                _platform == "android"
                                    ? 'Загрузка обновления'
                                    : 'Загрузка установщика',
                                style: TextStyle(color: colors.textColor),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: progressProvider.progress / 100,
                                    backgroundColor: colors.backgroundColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        colors.primaryColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Прогресс: ${progressProvider.progress}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Если загрузка не идёт, покажем возможность проверить обновления
                        return ListTile(
                          leading: Icon(Icons.system_update,
                              color: colors.iconColor),
                          title: Text(
                            'Проверить обновления',
                            style: TextStyle(color: colors.textColor),
                          ),
                          subtitle: Text(
                            'Текущая версия: ${VersionChecker.getCurrentVersion()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textColor.withOpacity(0.7),
                            ),
                          ),
                          onTap: () async {
                            try {
                              if (_platform == "android") {
                                final result =
                                    await versionManager.checkApkVersion(
                                        VersionChecker.getCurrentVersion(),
                                        context);
                                if (result['code'] == '400' ||
                                    result['code'] == '404' ||
                                    result['code'] == '201') {
                                  await versionManager
                                      .downloadAndInstallApk(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Ваша версия актуальна')),
                                  );
                                }
                              } else if (_platform == "windows") {
                                final result =
                                    await versionManager.checkWindowsVersion(
                                        VersionChecker.getCurrentVersion(),
                                        context);
                                if (result['code'] == '400' ||
                                    result['code'] == '404') {
                                  await versionManager
                                      .downloadWindowsInstaller(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Ваша версия актуальна')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Платформа не поддерживается для обновлений')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Ошибка при проверке обновлений: $e')),
                              );
                            }
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ссылки на поддержку
          Card(
            color: colors.cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help, color: colors.iconColor),
                  title:
                      Text('Помощь', style: TextStyle(color: colors.textColor)),
                  onTap: () {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'SHSH.Inc@yandex.ru',
                      queryParameters: {
                        'subject': 'Вопрос по приложению',
                        'body': 'Здравствуйте! У меня возник следующий вопрос:',
                      },
                    );
                    launchUrl(emailUri);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: colors.iconColor),
                  title: Text('Политика конфиденциальности',
                      style: TextStyle(color: colors.textColor)),
                  onTap: () {
                    launchUrlString('https://disk.yandex.ru/i/QwxUMTvtYEvECA');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.description, color: colors.iconColor),
                  title: Text('Условия использования',
                      style: TextStyle(color: colors.textColor)),
                  onTap: () {
                    launchUrlString('https://disk.yandex.ru/d/UntqhFW-lFpdGQ');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Кнопка поддержки
          if (Platform.isWindows)
            Padding(
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
            ),
          const SizedBox(height: 16),
        ],
      ),
      backgroundColor: colors.backgroundColor,
    );
  }
}
