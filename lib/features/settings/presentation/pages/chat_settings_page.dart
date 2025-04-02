import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/app_settings.dart';
import 'wallpaper_selection_page.dart';
import '../widgets/chat_list_type_selector.dart';
import '../widgets/chat_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:math';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/new_year/new_year_snowfall.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../main/domain/entities/chat.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../data/services/theme_manager.dart';
import 'package:http/http.dart' as http;
import '../pages/settings_page.dart';

class ChatSettingsPage extends StatefulWidget {
  @override
  _ChatSettingsPageState createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  double _messageTextSize = 16.0;
  String _wallpaper = '';
  String _chatListType = 'two_line';
  double _messageCornerRadius = 8.0;
  String _swipeAction = 'Нет';
  String _selectedAnimation = "none";
  bool _isPremium = false;
  String? _activeAnimationCard;

  late FixedExtentScrollController _swipeActionController =
      FixedExtentScrollController();

  final List<String> _actions = [
    'Нет',
    'Удалить',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    int selectedIndex = _actions.indexOf(AppSettings.swipeAction);
    _swipeActionController =
        FixedExtentScrollController(initialItem: selectedIndex);
    _loadSettings().then((_) {
      int selectedIndex = _actions.indexOf(AppSettings.swipeAction);
      _swipeActionController =
          FixedExtentScrollController(initialItem: selectedIndex);
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _messageTextSize = prefs.getDouble('message_text_size') ?? 16.0;
      _wallpaper = prefs.getString('wallpaper') ?? '';
      _chatListType = prefs.getString('chat_list_type') ?? 'two_line';
      _messageCornerRadius = prefs.getDouble('message_corner_radius') ?? 8.0;
      _swipeAction = prefs.getString('swipe_action') ?? 'archive';
      _swipeActionController = FixedExtentScrollController(
        initialItem: _actions.indexOf(_swipeAction),
      );
      _selectedAnimation = prefs.getString('selected_animation') ?? "none";
    });
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
      throw ServerException('Токен недоступен');
    }
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw CacheException();
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw CacheException();
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      await TokenManager.refreshToken();

      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw CacheException();
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw CacheException();
      }

      response = await request();
    }

    return response;
  }

  Future<ProfileModel> getProfile(String userId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await http.Client().get(
          Uri.parse(
              '${Constants.baseUrl}${Constants.getUserProfileEndpoint}$userId'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        return ProfileModel.fromJson(
            json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw ServerException(response.statusCode.toString());
      }
    } catch (e) {
      throw ServerException();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await getProfile(await _getUserId());
      setState(() {
        _isPremium = profile.premium;
      });
    } catch (e) {
      print('Ошибка при загрузке профиля: $e');
    }
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      final userMap = json.decode(cachedUser) as Map<String, dynamic>;
      final userId = UserModel.fromJson(userMap).id;
      if (userId != null) {
        return userId;
      }
    }
    return '';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('message_text_size', _messageTextSize);
    await prefs.setString('wallpaper', _wallpaper);
    await prefs.setString('chat_list_type', _chatListType);
    await prefs.setDouble('message_corner_radius', _messageCornerRadius);
    await prefs.setString('swipe_action', _swipeAction);
    await prefs.setString('selected_animation', _selectedAnimation);
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Настройки чатов', style: TextStyle(color: colors.textColor)),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: ListView(
        children: [
          // 1. Настройки внешнего вида сообщений
          _buildMessageTextSizeSetting(colors), // Размер текста сообщений
          _buildDivider(colors: colors),
          _buildMessageCornerRadiusSetting(colors), // Углы сообщений
          _buildDivider(colors: colors),

          // 2. Настройки отображения чатов в списке
          _buildChatListTypeSetting(colors), // Тип списка чатов
          _buildDivider(colors: colors),
          _buildSwipeActionSetting(
            colors,
          ), // Действие при свайпе
          _buildDivider(colors: colors),

          // 3. Обои и анимации
          _buildWallpaperSetting(colors), // Обои
          _buildDivider(colors: colors),
          _buildAnimationSelection(colors), // Анимации
        ],
      ),
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget _buildMessageTextSizeSetting(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Размер текста сообщений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        Slider(
          value: _messageTextSize,
          min: 12,
          max: 25,
          divisions: 13,
          label: _messageTextSize.round().toString(),
          onChanged: (double value) {
            setState(() {
              _messageTextSize = value;
              _saveSettings();
            });
          },
          activeColor: isWhiteNotifier.value ? Colors.grey : Colors.white,
          inactiveColor: colors.textColor.withOpacity(0.3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ChatPreview(
            messageCornerRadius: _messageCornerRadius,
            messageTextSize: _messageTextSize,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperSetting(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Обои',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WallpaperSelectionPage(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colors.appBarColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: colors.textColor,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Изменить обои',
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatListTypeSetting(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Список чатов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChatListTypeSelector(
                title: 'Двухстрочный',
                isSelected: _chatListType == 'two_line',
                onTap: () {
                  if (_chatListType != 'two_line') {
                    setState(() {
                      _chatListType = 'two_line';
                      _saveSettings();
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: ChatListTypeSelector(
                title: 'Трёхстрочный',
                isSelected: _chatListType == 'three_line',
                onTap: () {
                  if (_chatListType != 'three_line') {
                    setState(() {
                      _chatListType = 'three_line';
                      _saveSettings();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageCornerRadiusSetting(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Углы блоков с сообщениями',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        Slider(
          value: _messageCornerRadius,
          min: 0,
          max: 20,
          divisions: 20,
          label: _messageCornerRadius.round().toString(),
          onChanged: (double value) {
            setState(() {
              _messageCornerRadius = value;
              _saveSettings();
            });
          },
          activeColor: isWhiteNotifier.value ? Colors.grey : Colors.white,
          inactiveColor: colors.textColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildSwipeActionSetting(AppColors colors) {
    // Функция для получения иконки в зависимости от выбранного действия
    IconData _getSwipeIcon(String action) {
      switch (action) {
        case 'Удалить':
          return Icons.delete;
        case 'Архивировать':
          return Icons.archive;
        case 'Прочитать':
          return Icons.mark_email_read;
        default:
          return Icons.swipe_left; // Иконка по умолчанию
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Действие на свайп влево',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Пример свайпа (карточка чата)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.disabledColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -30,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: colors.appBarColor.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        top: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.backgroundColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 120,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.backgroundColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Иконка действия (справа от карточки)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.backgroundColor.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getSwipeIcon(_swipeAction),
                              color: colors.textColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // CupertinoPicker справа (уменьшенный)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 16.0),
                child: SizedBox(
                  height: 80,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _swipeAction = _actions[index];
                        AppSettings.swipeAction = _swipeAction;
                        _saveSettings();
                      });
                    },
                    scrollController:
                        _swipeActionController, // Используем контроллер из состояния
                    children: _actions.map((String action) {
                      return Center(
                        child: Text(
                          action,
                          style: TextStyle(
                            color: colors.textColor,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimationSelection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Анимация',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildAnimationCard(
              key: "none",
              label: "Нет",
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red, width: 2.0),
                ),
                child: Center(
                  child: Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 48.0,
                  ),
                ),
              ),
              isSelected: _selectedAnimation == "none",
              colors: colors,
              isLocked: false, // Анимация "Нет" всегда доступна
              onLongPress: () {
                setState(() {
                  _selectedAnimation = "none";
                  _saveSettings();
                });
              },
            ),
            _buildAnimationCard(
              key: "snowflakes",
              label: "Снежинки",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: NewYearSnowfall(
                    animationType: "snowflakes",
                    isPlaying: _activeAnimationCard == "snowflakes",
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: _selectedAnimation == "snowflakes"
                              ? isWhiteNotifier.value
                                  ? Colors.grey
                                  : Colors.white
                              : colors.textColor.withOpacity(0.3),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              isSelected: _selectedAnimation == "snowflakes",
              colors: colors,
              isLocked: false, // Анимация "Снежинки" всегда доступна
              onLongPress: () {
                setState(() {
                  _selectedAnimation = "snowflakes";
                  _saveSettings();
                });
              },
            ),
            _buildAnimationCard(
              key: "hearts",
              label: "Сердечки",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: NewYearSnowfall(
                    animationType: "hearts",
                    isPlaying: _activeAnimationCard == "hearts",
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: _selectedAnimation == "hearts"
                              ? isWhiteNotifier.value
                                  ? Colors.grey
                                  : Colors.white
                              : colors.textColor.withOpacity(0.3),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              isSelected: _selectedAnimation == "hearts",
              colors: colors,
              isLocked:
                  !_isPremium, // Анимация "Сердечки" доступна только для премиум-пользователей
              onLongPress: () {
                if (_isPremium) {
                  setState(() {
                    _selectedAnimation = "hearts";
                    _saveSettings();
                  });
                }
              },
            ),
            _buildAnimationCard(
              key: "smileys",
              label: "Смайлики",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: NewYearSnowfall(
                    animationType: "smileys",
                    isPlaying: _activeAnimationCard == "smileys",
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: _selectedAnimation == "smileys"
                              ? isWhiteNotifier.value
                                  ? Colors.grey
                                  : Colors.white
                              : colors.textColor.withOpacity(0.3),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              isSelected: _selectedAnimation == "smileys",
              colors: colors,
              isLocked:
                  !_isPremium, // Анимация "Смайлики" доступна только для премиум-пользователей
              onLongPress: () {
                if (_isPremium) {
                  setState(() {
                    _selectedAnimation = "smileys";
                    _saveSettings();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimationCard({
    required String key,
    required String label,
    required Widget child,
    required bool isSelected,
    required AppColors colors,
    required bool isLocked, // Новый аргумент
    VoidCallback? onLongPress,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: isLocked ? null : onLongPress,
          onLongPress: () {
            if (isLocked) return;
            setState(() {
              if (_activeAnimationCard == key) {
                _activeAnimationCard = null;
              } else {
                _activeAnimationCard = key;
              }
            });
          },
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.appBarColor.withOpacity(0.1)
                        : colors.backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: isSelected
                          ? isWhiteNotifier.value
                              ? Colors.grey
                              : Colors.white
                          : colors.textColor.withOpacity(0.3),
                      width: 2.0,
                    ),
                  ),
                  child: Center(child: child),
                ),
                if (isLocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.lock,
                      color: colors.textColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? isWhiteNotifier.value
                    ? Colors.grey
                    : Colors.white
                : colors.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider({required AppColors colors}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(
        color: colors.textColor.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }
}
