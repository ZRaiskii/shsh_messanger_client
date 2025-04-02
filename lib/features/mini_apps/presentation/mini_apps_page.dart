import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/features/mini_apps/presentation/widgets/wordle_mini_app/data/wordle_manager.dart';
import 'package:shsh_social/features/mini_apps/presentation/widgets/wordle_mini_app/presentation/pages/home_page.dart';
import '../category_app_page.dart';
import 'widgets/2048/home.dart';
import 'widgets/citatnik/presentation/quote_app_page.dart';
import 'widgets/criss_cross/presentation/criss_cross_screen.dart';
import 'widgets/generator_different_numbers/presentation/random_number_screen.dart';
import '../../../core/utils/AppColors.dart';
import 'widgets/news_miniapp/presentation/news_page.dart';
import 'widgets/snake_game_page.dart';
import 'widgets/custom_calendar_page.dart';
import 'widgets/step_counter_page.dart';
import 'widgets/clicker_game_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../settings/data/services/theme_manager.dart';
import 'widgets/base/mini_app_container.dart';

enum AppType { internal, web }

enum DeveloperType { internal, thirdParty }

enum AppCategory { games, utilities, news, productivity, entertainment }

class AppCategorySection {
  final String title;
  final AppCategory category;
  final String iconPath;
  final List<MiniAppCard> apps;

  AppCategorySection({
    required this.title,
    required this.category,
    required this.iconPath,
    required this.apps,
  });
}

class MiniAppCard {
  final AppCategory category;
  final String title;
  final String description;
  final String? imageUrl;
  final AppType appType;
  final DeveloperType developerType;
  final Widget? internalPage;
  final String? webUrl;
  final List<TargetPlatform> supportedPlatforms;
  final bool isNew;
  final bool isLocked;
  final bool isUpdated;

  // Дополнительные метаданные
  final String? version;
  final DateTime? releaseDate;
  final String? developerName;
  final String? developerContact;
  final List<String>? permissions;
  final Map<String, dynamic>? additionalData;

  int launchCount;
  bool isPinned;

  MiniAppCard({
    required this.category,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.appType,
    required this.developerType,
    this.internalPage,
    this.webUrl,
    this.supportedPlatforms = const [],
    this.isNew = false,
    this.isLocked = false,
    this.isUpdated = false,
    this.version,
    this.releaseDate,
    this.developerName,
    this.developerContact,
    this.permissions,
    this.additionalData,
    this.launchCount = 0,
    this.isPinned = false,
  }) : assert(
            (appType == AppType.internal && internalPage != null) ||
                (appType == AppType.web && webUrl != null),
            'internalPage required for internal apps, webUrl required for web apps');
}

class MiniAppsPage extends StatefulWidget {
  const MiniAppsPage({Key? key}) : super(key: key);

  @override
  _MiniAppsPageState createState() => _MiniAppsPageState();
}

class _MiniAppsPageState extends State<MiniAppsPage> {
  late Future<List<AppCategorySection>> appsFuture;

  @override
  void initState() {
    super.initState();
    appsFuture = _initializeCategorizedApps();
  }

  Future<List<MiniAppCard>> _initializeApps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return [
      MiniAppCard(
        title: 'Новогодняя змейка',
        category: AppCategory.games, // Категория добавлена
        description: 'С Новым 2025 годом!',
        imageUrl: 'assets/mini_apps/images/snake.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: SnakeGamePage(),
        supportedPlatforms: [TargetPlatform.android, TargetPlatform.iOS],
        version: '1.0.2',
        releaseDate: DateTime(2024, 12, 15),
        developerName: 'Команда разработки',
        permissions: ['internet'],
        launchCount: prefs.getInt('launchCount_Новогодняя змейка') ?? 0,
        isPinned: prefs.getBool('isPinned_Новогодняя змейка') ?? false,
      ),
      MiniAppCard(
        title: 'Календарь',
        category: AppCategory.productivity, // Категория добавлена
        description: 'Планируйте свои события',
        imageUrl: 'assets/mini_apps/images/calendar.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: CustomCalendarPage(),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
          TargetPlatform.macOS,
          TargetPlatform.linux,
        ],
        isLocked: false,
        version: '1.0.5',
        developerContact: 'calendar-support@team.com',
        launchCount: prefs.getInt('launchCount_Календарь') ?? 0,
        isPinned: prefs.getBool('isPinned_Календарь') ?? false,
      ),
      MiniAppCard(
        title: 'Шагомер',
        category: AppCategory.utilities, // Категория добавлена
        description: 'Следите за количеством шагов',
        imageUrl: 'assets/mini_apps/images/step_counter.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: StepCounterPage(),
        supportedPlatforms: [TargetPlatform.android, TargetPlatform.iOS],
        isLocked: true,
        permissions: ['sensors', 'activity_recognition'],
        additionalData: {'requires_sensor': true},
        launchCount: prefs.getInt('launchCount_Шагомер') ?? 0,
        isPinned: prefs.getBool('isPinned_Шагомер') ?? false,
      ),
      MiniAppCard(
        title: 'Кликер',
        category: AppCategory.games, // Категория добавлена
        description: 'Нажмите кнопку как можно больше раз',
        imageUrl: 'assets/mini_apps/images/clicker.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: ClickerGamePage(),
        supportedPlatforms: [TargetPlatform.android, TargetPlatform.iOS],
        isUpdated: true,
        version: '2.0.5',
        releaseDate: DateTime(2025, 02, 15),
        launchCount: prefs.getInt('launchCount_Кликер') ?? 0,
        isPinned: prefs.getBool('isPinned_Кликер') ?? false,
      ),
      MiniAppCard(
        title: 'Угадай слово',
        category: AppCategory.games, // Категория добавлена
        description:
            'Угадайте загаданное слово за минимальное количество попыток',
        imageUrl: 'assets/mini_apps/images/wordle.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: WordleHomePage(wordleManager: WordleManager()),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
        ],
        isNew: true,
        developerName: 'Word Games Team',
        launchCount: prefs.getInt('launchCount_Угадай слово') ?? 0,
        isPinned: prefs.getBool('isPinned_Угадай слово') ?? false,
      ),
      MiniAppCard(
        title: 'Новости',
        category: AppCategory.news, // Категория добавлена
        description: 'Узнавай последние новости!',
        imageUrl: 'assets/mini_apps/images/news.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: NewsScreen(),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
        ],
        isNew: true,
        developerContact: 'news-team@company.com',
        version: '1.3.0',
        launchCount: prefs.getInt('launchCount_Новости') ?? 0,
        isPinned: prefs.getBool('isPinned_Новости') ?? false,
      ),
      MiniAppCard(
        title: 'SOON',
        category: AppCategory.entertainment, // Категория добавлена
        description: 'скоро...',
        imageUrl: null,
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: Container(),
        supportedPlatforms: TargetPlatform.values,
        additionalData: {'coming_soon': true},
        launchCount: prefs.getInt('launchCount_SOON') ?? 0,
        isPinned: prefs.getBool('isPinned_SOON') ?? false,
      ),
      MiniAppCard(
        title: 'Цитатник',
        category: AppCategory.entertainment,
        description: 'Получайте случайные цитаты каждый день!',
        imageUrl: 'assets/mini_apps/images/quote.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: QuoteScreen(),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
        ],
        isNew: false,
        developerContact: 'quote-team@company.com',
        version: '1.0.0',
        launchCount: prefs.getInt('launchCount_Цитатник') ?? 0,
        isPinned: prefs.getBool('isPinned_Цитатник') ?? false,
      ),
      MiniAppCard(
        title: 'Крестики-нолики',
        category: AppCategory.games,
        description: 'Играйте в крестики-нолики!',
        imageUrl: 'assets/mini_apps/images/criss_cross.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: CrissCrossScreen(),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
        ],
        isNew: false,
        developerContact: 'game-team@company.com',
        version: '1.0.0',
        launchCount: prefs.getInt('launchCount_КрестикиНолики') ?? 0,
        isPinned: prefs.getBool('isPinned_КрестикиНолики') ?? false,
      ),
      MiniAppCard(
        title: '2048',
        category: AppCategory.games,
        description: 'Сложите плитки и достигните числа 2048!',
        imageUrl: 'assets/mini_apps/images/2048.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: HomePage(),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
        ],
        isNew: true,
        developerContact: 'game-team@company.com',
        version: '1.0.0',
        launchCount: prefs.getInt('launchCount_2048') ?? 0,
        isPinned:
            prefs.getBool('isPinned_2048') ?? false, // Закреплено ли приложение
      ),
      MiniAppCard(
        title: 'Генератор чисел',
        category: AppCategory.utilities,
        description: 'Генерируйте случайные числа в заданном диапазоне.',
        imageUrl: 'assets/mini_apps/images/random_number_generator.png',
        appType: AppType.internal,
        developerType: DeveloperType.internal,
        internalPage: RandomNumberScreen(),
        supportedPlatforms: [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.windows,
          TargetPlatform.macOS,
          TargetPlatform.linux,
        ],
        isNew: true,
        developerContact: 'tools-team@company.com',
        version: '1.0.0',
        launchCount: prefs.getInt('launchCount_random_number_generator') ?? 0,
        isPinned: prefs.getBool('isPinned_random_number_generator') ?? false,
      ),
    ]..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.launchCount.compareTo(a.launchCount);
      });
  }

  Future<List<AppCategorySection>> _initializeCategorizedApps() async {
    List<MiniAppCard> allApps = await _initializeApps();

    // Разделяем закрепленные и обычные приложения
    List<MiniAppCard> pinnedApps =
        allApps.where((app) => app.isPinned).toList();
    List<MiniAppCard> regularApps = allApps;

    // Создаем категории для обычных приложений
    Map<AppCategory, List<MiniAppCard>> categorized = {
      AppCategory.games: [],
      AppCategory.utilities: [],
      AppCategory.news: [],
      AppCategory.productivity: [],
      AppCategory.entertainment: [],
    };

    // Распределяем обычные приложения по категориям
    for (var app in regularApps) {
      categorized[app.category]!.add(app);
    }

    // Формируем секции категорий
    List<AppCategorySection> sections = [];

    // Добавляем секцию закрепленных приложений, если есть
    if (pinnedApps.isNotEmpty) {
      sections.add(AppCategorySection(
        title: 'Закрепленные',
        category: AppCategory.games, // Категория не важна для закрепленных
        iconPath: 'assets/categories/pinned.png', // Добавьте иконку
        apps: pinnedApps,
      ));
    }

    sections.addAll([
      AppCategorySection(
        title: 'Игры',
        category: AppCategory.games,
        iconPath: 'assets/categories/games.png',
        apps: categorized[AppCategory.games]!,
      ),
      AppCategorySection(
        title: 'Утилиты',
        category: AppCategory.utilities,
        iconPath: 'assets/categories/utilities.png',
        apps: categorized[AppCategory.utilities]!,
      ),
      AppCategorySection(
        title: 'Новости',
        category: AppCategory.news,
        iconPath: 'assets/categories/news.png',
        apps: categorized[AppCategory.news]!,
      ),
      AppCategorySection(
        title: 'Продуктивность',
        category: AppCategory.productivity,
        iconPath: 'assets/categories/productivity.png',
        apps: categorized[AppCategory.productivity]!,
      ),
      AppCategorySection(
        title: 'Развлечения',
        category: AppCategory.entertainment,
        iconPath: 'assets/categories/entertainment.png',
        apps: categorized[AppCategory.entertainment]!,
      ),
    ]);

    return sections;
  }

  int _getClickCount(String appTitle, SharedPreferences prefs) {
    return prefs.getInt(appTitle) ?? 0;
  }

  void _incrementClickCount(String appTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int count = _getClickCount(appTitle, prefs);
    prefs.setInt(appTitle, count + 1);
    setState(() {
      appsFuture = _initializeCategorizedApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildAppBar(colors),
      ),
      body: FutureBuilder<List<AppCategorySection>>(
        future: appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error);
          } else if (snapshot.hasData) {
            // Получаем секции
            final sections = snapshot.data!;

            AppCategorySection? pinnedSection;
            try {
              pinnedSection = sections.firstWhere(
                (section) => section.title == 'Закрепленные',
              );
            } catch (e) {
              pinnedSection = null;
            }

            // Остальные категории
            final categories = sections
                .where((section) => section.title != 'Закрепленные')
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Закрепленные приложения
                  if (pinnedSection != null && pinnedSection.apps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Закрепленные',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textColor,
                        ),
                      ),
                    ),
                  if (pinnedSection != null && pinnedSection.apps.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pinnedSection.apps.length,
                        itemBuilder: (context, index) {
                          final app = pinnedSection!.apps[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AppCard(
                              app: app,
                              colors: colors,
                              isSupported: true,
                              onTap: () => _handleAppTap(context, app),
                              onPinToggle: () => _togglePin(app.title),
                            ),
                          );
                        },
                      ),
                    ),

                  // Категории
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Категории',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryAppsPage(
                                  categoryTitle: category.title,
                                  category: category.category,
                                  apps: category.apps,
                                ),
                              ),
                            );
                          },
                          child: CategoryCard(
                            title: category.title,
                            icon: _getCategoryIcon(category.category),
                            color: _getCategoryColor(category.category),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildAppBar(AppColors colors) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        color: colors.appBarColor,
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Мини-Приложения',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.textColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
        ),
      ),
    );
  }

  Widget _buildError(error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text('ПОВТОРИТЬ'),
          ),
        ],
      ),
    );
  }

  bool _checkPlatformSupport(MiniAppCard app) {
    return app.supportedPlatforms.isEmpty ||
        app.supportedPlatforms.contains(Theme.of(context).platform);
  }

  void _handleAppTap(BuildContext context, MiniAppCard app) {
    if (!app.isLocked && _checkPlatformSupport(app)) {
      _incrementLaunchCount(app.title);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Приложений не найдено',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  int _getLaunchCount(String appTitle, SharedPreferences prefs) {
    return prefs.getInt('launchCount_$appTitle') ?? 0;
  }

  void _incrementLaunchCount(String appTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int count = _getLaunchCount(appTitle, prefs);
    prefs.setInt('launchCount_$appTitle', count + 1);
  }

  bool _isPinned(String appTitle, SharedPreferences prefs) {
    return prefs.getBool('isPinned_$appTitle') ?? false;
  }

  void _togglePin(String appTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isCurrentlyPinned = _isPinned(appTitle, prefs);
    prefs.setBool('isPinned_$appTitle', !isCurrentlyPinned);
    setState(() {
      appsFuture = _initializeCategorizedApps();
    });
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _getCategoryIcon(AppCategory category) {
  switch (category) {
    case AppCategory.games:
      return Icons.sports_esports;
    case AppCategory.utilities:
      return Icons.settings;
    case AppCategory.news:
      return Icons.newspaper;
    case AppCategory.productivity:
      return Icons.work;
    case AppCategory.entertainment:
      return Icons.movie;
    default:
      return Icons.apps;
  }
}

Color _getCategoryColor(AppCategory category) {
  switch (category) {
    case AppCategory.games:
      return Colors.blue;
    case AppCategory.utilities:
      return Colors.green;
    case AppCategory.news:
      return Colors.red;
    case AppCategory.productivity:
      return Colors.orange;
    case AppCategory.entertainment:
      return Colors.purple;
    default:
      return Colors.grey;
  }
}

class AppCard extends StatelessWidget {
  final MiniAppCard app;
  final AppColors colors;
  final bool isSupported;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;

  const AppCard({
    required this.app,
    required this.colors,
    required this.isSupported,
    required this.onTap,
    required this.onPinToggle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth > 800 ? 60.0 : 48.0;
    final titleFontSize = screenWidth > 800 ? 14.0 : 12.0;
    final descriptionFontSize = screenWidth > 800 ? 10.0 : 9.0;

    return GestureDetector(
      onTap: app.isLocked || !isSupported ? null : onTap,
      child: SizedBox(
        // Явно задаем ширину и высоту карточки
        width: 150, // Фиксированная ширина
        height: 300, // Фиксированная высота
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none, // Предотвращаем обрезание содержимого
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Изображение
                  Expanded(
                    flex: 2, // Больше места для изображения
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        image: app.imageUrl != null
                            ? DecorationImage(
                                image: AssetImage(app.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: isSupported
                                    ? null
                                    : ColorFilter.mode(
                                        Colors.black12, BlendMode.srcOver),
                              )
                            : null,
                      ),
                      child: app.imageUrl == null
                          ? Center(
                              child: Icon(Icons.apps,
                                  size: imageSize,
                                  color: colors.iconColor.withOpacity(0.3)),
                            )
                          : null,
                    ),
                  ),
                  // Текстовая информация
                  Expanded(
                    flex: 1, // Меньше места для текста
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: colors.textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Метки (НОВИНКА, ОБНОВЛЕНО, ЗАБЛОКИРОВАНО)
              if (app.isNew)
                Positioned(
                  top: 6,
                  left: 6,
                  child: _buildBadge('НОВИНКА', Colors.red),
                ),
              if (app.isUpdated)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _buildBadge('ОБНОВЛЕНО', Colors.blue),
                ),
              if (app.isLocked)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Icon(Icons.lock, color: Colors.grey, size: 14),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  icon: Icon(
                    app.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onPressed: onPinToggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
