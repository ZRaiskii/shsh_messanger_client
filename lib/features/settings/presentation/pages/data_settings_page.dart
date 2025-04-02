import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:disk_space/disk_space.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/AppColors.dart';
import '../../data/services/theme_manager.dart';
import 'package:fl_chart/fl_chart.dart'; // Для диаграммы
import 'package:path_provider/path_provider.dart'; // Для получения директорий
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../../core/data_base_helper.dart';
import '../../../chat/domain/entities/message.dart';

class DataSettingsPage extends StatefulWidget {
  @override
  _DataSettingsPageState createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends State<DataSettingsPage> {
  int _cacheSize = 0; // Общий размер кеша в МБ
  int _imageCacheSize = 0; // Размер кеша изображений в МБ
  int _appDataSize = 0; // Размер данных приложения в МБ
  int _cachedDataSize = 0; // Размер данных приложения в МБ
  int _freeSpace = 0; // Размер данных приложения в МБ

  @override
  void initState() {
    super.initState();
    _loadStorageInfo().then((_) {
      print("Данные загружены и UI обновлен");
    }).catchError((error) {
      print("Ошибка при загрузке данных: $error");
    });
  }

  Future<void> _loadStorageInfo() async {
    // Получаем общий размер кеша из временной директории
    final tempDir = await getTemporaryDirectory();
    final cacheSize = await _getDirectorySize(tempDir);
    print('Общий размер кеша: $cacheSize байт');

    // Получаем размер кеша изображений через flutter_cache_manager
    final imageCacheSize = await _getImageCacheSize();
    print('Размер кеша изображений: $imageCacheSize байт');

    // Получаем размер данных приложения
    final appDir = await getApplicationDocumentsDirectory();
    final appDataSize = await _getDirectorySize(appDir);
    print('Размер данных приложения: $appDataSize байт');

    // Получаем размер кеша из SharedPreferences (чаты, сообщения и т.д.)
    final prefs = await SharedPreferences.getInstance();
    final cachedDataSize = await _getSharedPreferencesSize(prefs);
    print('Размер кеша SharedPreferences: $cachedDataSize байт');

    final freeSpace = await getFreeSpaceInMB();

    setState(() {
      _cacheSize = (cacheSize ~/ (1024 * 1024)); // Переводим в МБ
      _imageCacheSize = (imageCacheSize ~/ (1024 * 1024)); // Переводим в МБ
      _appDataSize = (appDataSize ~/ (1024 * 1024)); // Переводим в МБ
      _cachedDataSize =
          (cachedDataSize ~/ (1024 * 1024)) + _cacheSize; // Переводим в МБ
      _freeSpace = freeSpace ~/ (1024 * 1024);
    });
  }

  Future<int> _getImageCacheSize() async {
    final cacheManager = DefaultCacheManager();
    int totalCacheSize = 0;

    // Получаем все сообщения пользователя
    final List<Message> messages = await _getMessagesForUser();

    // Получаем все профили пользователей
    final List<Map<String, dynamic>> profiles = await _getAllProfiles();

    // Собираем URL изображений из сообщений
    final List<String> imageUrls = [];
    for (final message in messages) {
      if (message.content.startsWith("http") &&
          (message.content.endsWith("png") ||
              message.content.endsWith("jpg")) &&
          !imageUrls.contains(message.content)) {
        imageUrls.add(message.content);
      }
    }

    // Собираем URL изображений из профилей
    print(profiles);
    print(profiles.length);
    for (final profile in profiles) {
      if (profile['avatarUrl'] != null &&
          profile['avatarUrl'].isNotEmpty &&
          !imageUrls.contains(profile['avatarUrl'])) {
        imageUrls.add(profile['avatarUrl']);
      }
      if (profile['chatWallpaperUrl'] != null &&
          profile['chatWallpaperUrl'].isNotEmpty &&
          !imageUrls.contains(profile['chatWallpaperUrl'])) {
        imageUrls.add(profile['chatWallpaperUrl']);
      }
    }

    // Для каждого изображения получаем размер кеша

    for (final imageUrl in imageUrls) {
      final cachedFile = await cacheManager.getFileFromCache(imageUrl);
      if (cachedFile != null) {
        final fileSize = await cachedFile.file.length();
        totalCacheSize += fileSize;
      }
    }

    print('Total cache size: ${totalCacheSize / 1024 / 1024} MB');
    return totalCacheSize;
  }

  Future<int> getFreeSpaceInMB() async {
    // try {
    //   final freeSpace = await DiskSpace.getFreeDiskSpace ?? 0.0;
    //   print("freeSpace: $freeSpace");
    //   return freeSpace ~/ (1024 * 1024);
    // } catch (e) {
    //   print('Ошибка при получении свободного места: $e');
    // }
    return 0;
  }

  List<String> _extractImageUrls(String content) {
    final RegExp urlRegex = RegExp(
      r'(https?:\/\/[^\s]+\.(?:jpg|jpeg|png|gif|webp))',
      caseSensitive: false,
    );
    return urlRegex
        .allMatches(content)
        .map((match) => match.group(0)!)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getAllProfiles() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('profiles');
    return maps;
  }

  Future<List<Message>> _getMessagesForUser() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('messages');
    return List.generate(maps.length, (i) {
      return Message.fromJson(maps[i]);
    });
  }

  Future<int> _getSharedPreferencesSize(SharedPreferences prefs) async {
    int size = 0;
    final keys = prefs.getKeys();
    for (var key in keys) {
      final value = prefs.get(key); // Получаем значение как динамический тип
      if (value is String) {
        size += value.length * 2; // Каждый символ в UTF-16 занимает 2 байта
      } else if (value is int || value is double) {
        size += 8; // int и double занимают 8 байт
      } else if (value is bool) {
        size += 1; // bool занимает 1 байт
      } else if (value is List<String>) {
        for (var item in value) {
          size += item.length * 2; // Каждый элемент списка строк
        }
      }
    }
    return size;
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    final files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is File) {
        size += await file.length();
      }
    }
    return size;
  }

  Future<void> _clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Кеш изображений успешно очищен')),
    );
    await _loadStorageInfo();
  }

  Future<void> _clearAppCache() async {
    final tempDir = await getTemporaryDirectory();
    await _deleteDirectory(tempDir);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Общий кеш успешно очищен')),
    );
    await _loadStorageInfo();
  }

  Future<void> _showClearCacheDialog(String cacheType) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Очистка кеша'),
          content: Text('Вы уверены, что хотите очистить $cacheType?'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
            ),
            TextButton(
              child: Text('Очистить', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
                if (cacheType == 'кеш изображений') {
                  _clearImageCache();
                } else if (cacheType == 'общий кеш') {
                  _clearAppCache();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDirectory(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Данные и память', style: TextStyle(color: colors.textColor)),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Диаграмма использования памяти
          Card(
            color: colors.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Использование памяти',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          if (_imageCacheSize > 0)
                            PieChartSectionData(
                              value: _imageCacheSize.toDouble(),
                              color: Colors.blue,
                              title: '${_imageCacheSize} МБ',
                              radius: 50,
                              titleStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_appDataSize > 0)
                            PieChartSectionData(
                              value: _appDataSize.toDouble(),
                              color: Colors.green,
                              title: '${_appDataSize} МБ',
                              radius: 50,
                              titleStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_cachedDataSize > 0)
                            PieChartSectionData(
                              value: _cachedDataSize.toDouble(),
                              color: Colors.orange,
                              title: '${_cachedDataSize} МБ',
                              radius: 50,
                              titleStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_freeSpace > 0)
                            PieChartSectionData(
                              value: _freeSpace.toDouble(),
                              color: Colors.grey,
                              title: '${_freeSpace} МБ',
                              radius: 50,
                              titleStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Кеш изображений: ${_imageCacheSize > 0 ? '$_imageCacheSize МБ' : '0 МБ'}',
                    style: TextStyle(
                      color: colors.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Данные приложения: ${_appDataSize > 0 ? '$_appDataSize МБ' : '0 МБ'}',
                    style: TextStyle(
                      color: colors.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Кеш данных: ${_cachedDataSize > 0 ? '$_cachedDataSize МБ' : '0 МБ'}',
                    style: TextStyle(
                      color: colors.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Блок "Очистить кеш"
          Card(
            color: colors.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Очистка кеша',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textColor.withOpacity(0.7),
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Очистить кеш изображений',
                      style: TextStyle(color: colors.textColor)),
                  trailing: Icon(Icons.image, color: colors.iconColor),
                  onTap: () => _showClearCacheDialog('кеш изображений'),
                ),
                ListTile(
                  title: Text('Очистить общий кеш',
                      style: TextStyle(color: colors.textColor)),
                  trailing: Icon(Icons.delete, color: colors.iconColor),
                  onTap: () => _showClearCacheDialog('общий кеш'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Блок "Управление хранилищем"
          Card(
            color: colors.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Управление хранилищем',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textColor.withOpacity(0.7),
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Управление хранилищем',
                      style: TextStyle(color: colors.textColor)),
                  trailing: Icon(Icons.storage, color: colors.iconColor),
                  onTap: () {
                    // Логика для управления хранилищем
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundColor,
    );
  }
}
