import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../../../../core/app_settings.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final WindowsNotification _winNotifyPlugin = WindowsNotification(
    applicationId: "Уведомление от ЩЩ",
  );

  int id = 0;

  NotificationService() {
    if (kIsWeb) {
      return;
    }
    if (Platform.isWindows) {
      _initializeWindowsNotifications();
      return;
    }
    _configureLocalTimeZone();
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  Future<String> _copyIconToFileSystem() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;

      final String iconPath = '$tempPath/shsh.ico';

      final File file = File(iconPath);
      if (await file.exists()) {
        await file.delete();
        print('Старая иконка удалена: $iconPath');
      }

      final ByteData data = await rootBundle.load('assets/icons/shsh.ico');
      print('Иконка загружена из assets.');

      await file.writeAsBytes(data.buffer.asUint8List());
      print('Иконка успешно записана: $iconPath');

      return iconPath;
    } catch (e) {
      print('Ошибка при копировании иконки: $e');
      rethrow;
    }
  }

  Future<void> _initializeWindowsNotifications() async {
    try {
      final String iconPath = await _copyIconToFileSystem();

      if (iconPath.isEmpty) {
        throw Exception('Путь к иконке не был загружен.');
      }

      final File iconFile = File(iconPath);
      if (!await iconFile.exists()) {
        throw Exception('Файл иконки не существует: $iconPath');
      }

      print('WinToast успешно инициализирован.');
    } catch (e) {
      print('Ошибка при инициализации WinToast: $e');
    }
  }

  String _getReplacementEmoji(String body) {
    final String fileName = body.split('/').last.split('.').first;

    switch (fileName) {
      case '100':
        return '💯';
      case 'alarm-clock':
        return '⏰';
      case 'battary-full':
        return '🔋';
      case 'battary-low':
        return '🪫';
      case 'birthday-cake':
        return '🎂';
      case 'blood':
        return '🩸';
      case 'blush':
        return '😊';
      case 'bomb':
        return '💣';
      case 'bowling':
        return '🎳';
      case 'broking-heart':
        return '💔';
      case 'chequered-flag':
        return '🏁';
      case 'chinking-beer-mugs':
        return '🍻';
      case 'clap':
        return '👏';
      case 'clown':
        return '🤡';
      case 'cold-face':
        return '🥶';
      case 'collision':
        return '💥';
      case 'confetti-ball':
        return '🎊';
      case 'cross-mark':
        return '❌';
      case 'crossed-fingers':
        return '🤞';
      case 'crystal-ball':
        return '🔮';
      case 'cursing':
        return '🤬';
      case 'die':
        return '🎲';
      case 'dizy-dace':
        return '😵';
      case 'drool':
        return '🤤';
      case 'exclamation':
        return '❗';
      case 'experssionless':
        return '😑';
      case 'eyes':
        return '👀';
      case 'fire':
        return '🔥';
      case 'folded-hands':
        return '🙏';
      case 'gear':
        return '⚙️';
      case 'grimacing':
        return '😬';
      case 'Grin':
        return '😁';
      case 'Grinning':
        return '😀';
      case 'halo':
        return '😇';
      case 'heart-eyes':
        return '😍';
      case 'heart-face':
        return '🥰';
      case 'holding-back-tears':
        return '🥹';
      case 'hot-face':
        return '🥵';
      case 'hug-face':
        return '🤗';
      case 'imp-smile':
        return '😈';
      case 'Joy':
        return '😂';
      case 'kiss':
        return '💋';
      case 'Kissing-closed-eyes':
        return '😚';
      case 'Kissing-heart':
        return '😘';
      case 'Kissing':
        return '😗';
      case 'Launghing':
        return '😆';
      case 'light-bulb':
        return '💡';
      case 'Loudly-crying':
        return '😭';
      case 'melting':
        return '🫠';
      case 'mind-blown':
        return '🤯';
      case 'money-face':
        return '🤑';
      case 'money-wings':
        return '💸';
      case 'mouth-none':
        return '😶';
      case 'muscle':
        return '💪';
      case 'neutral-face':
        return '😐';
      case 'party-popper':
        return '🎉';
      case 'partying-face':
        return '🥳';
      case 'pencil':
        return '✏️';
      case 'pensive':
        return '😔';
      case 'pig':
        return '🐷';
      case 'pleading':
        return '🥺';
      case 'poop':
        return '💩';
      case 'question':
        return '❓';
      case 'rainbow':
        return '🌈';
      case 'raised-eyebrow':
        return '🤨';
      case 'relieved':
        return '😌';
      case 'revolving-heart':
        return '💞';
      case 'Rofl':
        return '🤣';
      case 'roling-eyes':
        return '🙄';
      case 'salute':
        return '🫡';
      case 'screaming':
        return '😱';
      case 'shushing-face':
        return '🤫';
      case 'skull':
        return '💀';
      case 'sleep':
        return '😴';
      case 'slot-machine':
        return '🎰';
      case 'smile':
        return '😊';
      case 'smile_with_big_eyes':
        return '😄';
      case 'smirk':
        return '😏';
      case 'soccer-bal':
        return '⚽';
      case 'sparkles':
        return '✨';
      case 'stuck-out-tongue':
        return '😛';
      case 'subglasses-face':
        return '😎';
      case 'thermometer-face':
        return '🤒';
      case 'thinking-face':
        return '🤔';
      case 'thumbs-down':
        return '👎';
      case 'thumbs-up':
        return '👍';
      case 'upside-down-face':
        return '🙃';
      case 'victory':
        return '✌️';
      case 'vomit':
        return '🤮';
      case 'warm-smile':
        return '☺️';
      case 'wave':
        return '👋';
      case 'Wink':
        return '😉';
      case 'winky-tongue':
        return '😜';
      case 'woozy':
        return '🥴';
      case 'yawn':
        return '🥱';
      case 'yum':
        return '😋';
      case 'zany-face':
        return '🤪';
      case 'zipper-face':
        return '🤐';
      default:
        return '✨';
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      return;
    }

    // Проверяем, включены ли уведомления в приложении
    if (!AppSettings.inAppNotifications) {
      return; // Если уведомления выключены, ничего не делаем
    }

    // Проверяем, является ли сообщение Lottie-анимацией
    final bool isLottieMessage = body.startsWith('::animation_emoji/');

    // Если это Lottie-анимация, заменяем её на обычный emoji
    final String notificationBody =
        isLottieMessage ? _getReplacementEmoji(body) : body;

    final bool isImageLink = body.startsWith('http') &&
        (body.endsWith('.png') ||
            body.endsWith('.jpg') ||
            body.endsWith('.jpeg'));

    String? imagePath;
    if (isImageLink) {
      try {
        imagePath = await _downloadAndSaveImage(body);
      } catch (e) {
        print('Ошибка при загрузке изображения: $e');
        imagePath = null;
      }
    }

    final String finalBody = isImageLink ? '📷 фотография' : notificationBody;

    if (Platform.isWindows) {
      final String iconPath = await _copyIconToFileSystem();

      final message = NotificationMessage.fromPluginTemplate(
        "notification_${DateTime.now().millisecondsSinceEpoch}",
        title,
        finalBody,
        image: iconPath,
        largeImage: imagePath, // Передаем путь к скачанному изображению
        launch: payload,
      );

      // Показываем уведомление
      _winNotifyPlugin.showNotificationPluginTemplate(message);
      return;
    }
  }

// Функция для скачивания и сохранения изображения
  Future<String> _downloadAndSaveImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Не удалось загрузить изображение: ${response.statusCode}');
    }

    final directory =
        await getTemporaryDirectory(); // Получаем временную директорию
    final file = File('${directory.path}/${url.hashCode}.png'); // Создаем файл
    await file.writeAsBytes(response.bodyBytes); // Сохраняем изображение
    return file.path; // Возвращаем путь к файлу
  }

  Future<void> showBackgroundNotification() async {
    if (Platform.isWindows) {
      // // Используем win_toast для Windows
      // WinToast.instance().showToast(
      //   toast: Toast(
      //     children: [
      //       ToastText('Приложение ЩЩ'), // Заголовок уведомления
      //       ToastText('Работает в фоновом режиме'), // Текст уведомления
      //     ],
      //     duration: ToastDuration.short, // Длительность уведомления
      //   ),
      // );
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'background_channel',
      'Фоновый режим',
      channelDescription: 'Уведомления о работе приложения в фоновом режиме',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      ongoing: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Приложение ЩЩ',
      'Работает в фоновом режиме',
      platformChannelSpecifics,
    );
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      final dynamic timestampMillis = data["timestampMillis"];
      if (timestampMillis != null) {
        final DateTime timestamp =
            DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true);
      }
    }
  }

  Future<bool> _loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
