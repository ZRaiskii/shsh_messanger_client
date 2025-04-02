import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/mini_apps_page.dart';
import '../../core/utils/AppColors.dart';
import 'presentation/widgets/base/mini_app_container.dart';
import '../settings/data/services/theme_manager.dart';

class CategoryAppsPage extends StatefulWidget {
  final String categoryTitle;
  final AppCategory category;
  final List<MiniAppCard> apps;

  const CategoryAppsPage({
    Key? key,
    required this.categoryTitle,
    required this.category,
    required this.apps,
  }) : super(key: key);

  @override
  _CategoryAppsPageState createState() => _CategoryAppsPageState();
}

class _CategoryAppsPageState extends State<CategoryAppsPage> {
  late List<MiniAppCard> apps;

  @override
  void initState() {
    super.initState();
    apps = widget.apps;
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    final screenWidth = MediaQuery.of(context).size.width;

    int _getCrossAxisCount(double width) {
      if (width > 1200) return 5;
      if (width > 800) return 4;
      if (width > 600) return 3;
      return 2;
    }

    double _getChildAspectRatio(double width) {
      if (width > 1200) return 0.5;
      if (width > 800) return 0.6;
      return 0.7;
    }

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: colors.textColor,
          ),
        ),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(
          color: colors.textColor,
        ),
        automaticallyImplyLeading: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(screenWidth),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: _getChildAspectRatio(screenWidth),
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          final isSupported = _checkPlatformSupport(app, context);
          return AppCard(
            app: app,
            colors: colors,
            isSupported: isSupported,
            onTap: () => _handleAppTap(context, app),
            onPinToggle: () => _togglePin(context, app.title),
          );
        },
      ),
    );
  }

  // Проверка поддержки платформы
  bool _checkPlatformSupport(MiniAppCard app, BuildContext context) {
    return app.supportedPlatforms.isEmpty ||
        app.supportedPlatforms.contains(Theme.of(context).platform);
  }

  // Обработка нажатия на приложение
  void _handleAppTap(BuildContext context, MiniAppCard app) async {
    if (!app.isLocked && _checkPlatformSupport(app, context)) {
      await _incrementLaunchCount(app.title);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniAppContainer(
            miniApp: app.internalPage!,
            appInfo: app,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Недоступно'),
          content: Text(app.isLocked
              ? 'Приложение заблокировано'
              : 'Не поддерживается вашей платформой'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Управление закреплением
  Future<void> _togglePin(BuildContext context, String appTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isCurrentlyPinned = prefs.getBool('isPinned_$appTitle') ?? false;
    await prefs.setBool('isPinned_$appTitle', !isCurrentlyPinned);

    // Обновляем состояние приложения
    setState(() {
      for (var app in apps) {
        if (app.title == appTitle) {
          app.isPinned = !isCurrentlyPinned;
          break;
        }
      }
    });
  }

  // Увеличение счетчика запусков
  Future<void> _incrementLaunchCount(String appTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('launchCount_$appTitle') ?? 0;
    await prefs.setInt('launchCount_$appTitle', count + 1);
  }
}
