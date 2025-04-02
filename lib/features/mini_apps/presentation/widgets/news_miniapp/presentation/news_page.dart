import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Импортируем пакет Shimmer
import '../../../../../../core/utils/AppColors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../settings/data/services/theme_manager.dart';
import '../data/currency_manager.dart';
import '../data/news_manager.dart';

enum CurrencyLoadingState { initial, loading, loaded, error }

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<News>> futureNews;
  late String currentTime;
  late Timer _timer;
  late Timer _currencyTimer;
  final CurrencyManager _currencyManager = CurrencyManager();
  List<Currency> _currencies = [];
  Object? _currencyError;
  CurrencyLoadingState _currencyLoadingState = CurrencyLoadingState.initial;

  // Список доступных категорий
  final List<String> _allCategories = [
    'politics',
    'sports',
    'business',
    'technology',
    'entertainment',
    'health',
    'science',
    'lifestyle',
    'travel',
    'culture',
    'education',
    'environment',
    'other'
  ];

  // Выбранные категории
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _setupData();
    _startTimers();
  }

  void _setupData() {
    NewsManager newsManager = NewsManager();
    futureNews = newsManager.fetchNews();
    currentTime = _getFormattedTime();
    _loadCurrencies();
  }

  void _startTimers() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() => currentTime = _getFormattedTime());
    });
    _currencyTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadCurrencies();
    });
  }

  Future<void> _refreshNews() async {
    final newsManager = NewsManager();
    setState(() {
      futureNews =
          newsManager.fetchNews(categories: _selectedCategories.toList());
    });
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _currencyLoadingState = CurrencyLoadingState.loading;
      _currencyError = null;
    });
    try {
      final currencies = await _currencyManager.fetchCurrencies();
      if (mounted) {
        setState(() {
          _currencies = currencies;
          _currencyLoadingState = CurrencyLoadingState.loaded;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currencyError = e;
          _currencyLoadingState = CurrencyLoadingState.error;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _currencyTimer.cancel();
    super.dispose();
  }

  String _getFormattedTime() => DateFormat('HH:mm:ss').format(DateTime.now());

  Widget _buildCategorySelection(AppColors colors) {
    // Отображение категорий с их русскими названиями и иконками
    final Map<String, Map<String, dynamic>> categoryDetails = {
      'politics': {'name': 'Политика', 'icon': Icons.account_balance},
      'sports': {'name': 'Спорт', 'icon': Icons.sports_soccer},
      'business': {'name': 'Бизнес', 'icon': Icons.business_center},
      'technology': {'name': 'Технологии', 'icon': Icons.devices},
      'entertainment': {'name': 'Развлечения', 'icon': Icons.movie},
      'health': {'name': 'Здоровье', 'icon': Icons.health_and_safety},
      'science': {'name': 'Наука', 'icon': Icons.science},
      'lifestyle': {'name': 'Образ жизни', 'icon': Icons.self_improvement},
      'travel': {'name': 'Путешествия', 'icon': Icons.flight},
      'culture': {'name': 'Культура', 'icon': Icons.palette},
      'education': {'name': 'Образование', 'icon': Icons.school},
      'environment': {'name': 'Экология', 'icon': Icons.eco},
      'other': {'name': 'Другое', 'icon': Icons.more_horiz},
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _allCategories.map((category) {
          final isSelected = _selectedCategories.contains(category);
          final details = categoryDetails[category]!;
          final categoryName = details['name'];
          final categoryIcon = details['icon'];

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              avatar: Icon(
                categoryIcon,
                color: isSelected ? colors.buttonTextColor : colors.textColor,
              ),
              label: Text(
                categoryName,
                style: TextStyle(
                  color: isSelected ? colors.buttonTextColor : colors.textColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
                _refreshNews(); // Перезагружаем только новости
              },
              backgroundColor: colors.cardColor,
              selectedColor: colors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isWhiteNotifier,
      builder: (context, isWhite, child) {
        final colors = isWhite ? AppColors.light() : AppColors.dark();
        return Scaffold(
          backgroundColor: colors.backgroundColor,
          body: RefreshIndicator(
            onRefresh: _refreshNews,
            child: Column(
              children: [
                _buildTopPanel(colors),
                _buildCategorySelection(colors), // Добавляем выбор категорий
                Expanded(
                  child: FutureBuilder<List<News>>(
                    future: futureNews,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Показываем загрузку
                        return Shimmer.fromColors(
                          baseColor: colors.shimmerBase,
                          highlightColor: colors.shimmerHighlight,
                          child: ListView.builder(
                            itemCount: 5, // Примерное количество заглушек
                            itemBuilder: (context, index) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: colors.shimmerBase,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        width: 200,
                                        height: 20,
                                        color: colors.shimmerBase,
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        width: 250,
                                        height: 16,
                                        color: colors.shimmerBase,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Произошла ошибка: ${snapshot.error}",
                            style: TextStyle(color: colors.errorColor),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "Новостей пока нет",
                            style: TextStyle(color: colors.textColor),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else {
                        // Фильтруем новости: исключаем те, у которых нет изображения
                        List<News> filteredNews = snapshot.data!
                            .where((news) =>
                                news.imageUrl != null &&
                                news.imageUrl!.isNotEmpty)
                            .toList();
                        if (filteredNews.isEmpty) {
                          // Если после фильтрации новостей нет
                          return Center(
                            child: Text(
                              "Нет новостей с изображениями",
                              style: TextStyle(color: colors.textColor),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: filteredNews.length,
                          itemBuilder: (context, index) {
                            return _buildNewsCard(filteredNews[index], colors);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopPanel(AppColors colors) {
    return Card(
      margin: EdgeInsets.all(8),
      color: colors.cardColor,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Stack(
          children: [
            if (_currencyLoadingState == CurrencyLoadingState.loading &&
                _currencies.isEmpty)
              Center(
                child: Shimmer.fromColors(
                  baseColor: colors.shimmerBase,
                  highlightColor: colors.shimmerHighlight,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.shimmerBase,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              )
            else if (_currencyLoadingState == CurrencyLoadingState.error &&
                _currencies.isEmpty)
              Center(
                child: Icon(Icons.error_outline, color: colors.errorColor),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInfoChip('🕒 Время', currentTime, colors),
                    ..._currencies.map((c) => _buildCurrencyChip(c, colors)),
                    if (_currencyLoadingState == CurrencyLoadingState.loading)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Shimmer.fromColors(
                          baseColor: colors.shimmerBase,
                          highlightColor: colors.shimmerHighlight,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colors.shimmerBase,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (_currencyError != null)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: _buildErrorIcon(colors),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(News news, AppColors colors) {
    return Card(
      color: colors.cardColor,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Добавляем изображение, если оно есть
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  news.imageUrl!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 150,
                      color: colors.cardColor.withOpacity(0.3),
                      child: Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: colors.textColor.withOpacity(0.5), size: 40),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: colors.shimmerBase,
                      highlightColor: colors.shimmerHighlight,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: colors.shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (news.imageUrl != null) SizedBox(height: 12),
            // Заголовок новости
            Text(
              news.newsTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
            Divider(color: colors.dividerColor, height: 20),
            // Основной текст новости
            Text(
              news.newsBody,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: colors.textColor.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 12),
            // Кнопка "Читать больше"
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _launchUrl(news.newsLink),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Читать больше',
                    style: TextStyle(
                      color: colors.buttonTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, AppColors colors,
      {bool isCurrency = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isCurrency ? colors.secondaryColor : colors.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIcon(AppColors colors) {
    return Icon(
      Icons.error_outline,
      color: colors.errorColor,
      size: 20,
    );
  }

  Widget _buildCurrencyChip(Currency currency, AppColors colors) {
    final symbols = {'USD': '🇺🇸', 'EUR': '🇪🇺', 'BTC': '₿'};
    final format = NumberFormat.currency(
      symbol: symbols[currency.name] ?? '',
      decimalDigits: currency.name == 'BTC' ? 2 : 2,
      locale: 'en_US',
    );

    return _buildInfoChip(
      currency.name,
      format.format(currency.rate),
      colors,
      isCurrency: true,
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
