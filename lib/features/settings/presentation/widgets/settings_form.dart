import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/new_year/new_year_snowfall.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../data/services/theme_manager.dart';
import '../../domain/entities/settings.dart';
import '../../domain/usecases/update_settings_usecase.dart';
import '../bloc/settings_bloc.dart';
import '../pages/wallpaper_selection_page.dart';
import 'chat_list_type_selector.dart';
import 'chat_preview.dart';

class SettingsForm extends StatefulWidget {
  final Settings settings;

  const SettingsForm(
      {super.key, required this.settings, required String selectedAnimation});

  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  late bool _notificationsEnabled;
  late String _selectedAnimation; // Выбранная анимация
  late double _messageTextSize;
  late String _wallpaper;
  late String _chatListType;
  bool _isPremium = false; // Премиум-статус пользователя

  String? _activeAnimationCard; // Ключ активной карточки с анимацией

  @override
  void initState() {
    super.initState();
    _selectedAnimation = "none";
    _notificationsEnabled = widget.settings.notificationsEnabled;
    _messageTextSize = widget.settings.messageTextSize;
    _wallpaper = widget.settings.wallpaper;
    _chatListType = widget.settings.chatListType;

    _loadSettings().then((_) {
      setState(() {});
    });

    _loadProfile();
  }

  Future<void> _loadSettings() async {
    _notificationsEnabled = await _loadNotificationsEnabled();
    _messageTextSize = await _loadMessageTextSize();
    _chatListType = await _loadChatListType();
    _wallpaper = await _loadWallpaper();
    _selectedAnimation = await _loadSelectedAnimation() ?? "none";
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

  @override
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

  void _updateSettings() {
    final updatedSettings = Settings(
      language: widget.settings.language,
      notificationsEnabled: _notificationsEnabled,
      snowflakesEnabled: _selectedAnimation == "snowflakes",
      messageTextSize: _messageTextSize,
      wallpaper: _wallpaper,
      chatListType: _chatListType,
    );
    context.read<SettingsBloc>().add(
        UpdateSettingsEvent(UpdateSettingsParams(settings: updatedSettings)));
    _saveMessageTextSize(_messageTextSize);
    _saveChatListType(_chatListType);
    _saveSelectedAnimation(_selectedAnimation);
    _saveNotificationsEnabled(_notificationsEnabled);
    _saveWallpaper(_wallpaper);
  }

  Future<void> _saveNotificationsEnabled(bool notificationsEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', notificationsEnabled);
  }

  Future<void> _saveWallpaper(String wallpaper) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallpaper', wallpaper);
  }

  Future<void> _saveMessageTextSize(double messageTextSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('message_text_size', messageTextSize);
  }

  Future<void> _saveChatListType(String chatListType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_list_type', chatListType);
  }

  Future<void> _saveSelectedAnimation(String animation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_animation', animation);
  }

  Future<String?> _loadSelectedAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_animation');
  }

  Future<double> _loadMessageTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('message_text_size') ??
        widget.settings.messageTextSize;
  }

  Future<String> _loadChatListType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chat_list_type') ?? widget.settings.chatListType;
  }

  Future<String> _loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wallpaper') ?? widget.settings.wallpaper;
  }

  Future<bool> _loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ??
        widget.settings.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isWhiteNotifier,
      builder: (context, isWhite, child) {
        final colors = isWhite ? AppColors.light() : AppColors.dark();

        return ListView(
          shrinkWrap: true,
          children: [
            _buildNotificationSetting(colors),
            _buildDivider(startFromLeft: true, colors: colors),
            _buildAnimationSelection(colors),
            _buildDivider(startFromLeft: false, colors: colors),
            _buildMessageTextSizeSetting(colors),
            _buildDivider(startFromLeft: _isPremium, colors: colors),
            _buildWallpaperSetting(colors),
            _buildDivider(startFromLeft: _isPremium, colors: colors),
            _buildChatListTypeSetting(colors),
            const SizedBox(height: 32),
            _buildSupportAuthorsButton(context, colors),
            const SizedBox(height: 25),
          ],
        );
      },
    );
  }

  Widget _buildNotificationSetting(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Уведомления',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        SwitchListTile(
          inactiveTrackColor: colors.textColor.withOpacity(0.3),
          inactiveThumbColor: colors.textColor.withOpacity(0.5),
          value: _notificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value;
              _updateSettings();
            });
          },
          title: Text(
            'Включить уведомления',
            style: TextStyle(color: colors.textColor),
          ),
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
                  _updateSettings();
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
                  _updateSettings();
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
                    _updateSettings();
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
                    _updateSettings();
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
          onTap: () {
            if (isLocked)
              return; // Если анимация заблокирована, ничего не делаем
            setState(() {
              if (_activeAnimationCard == key) {
                _activeAnimationCard = null;
              } else {
                _activeAnimationCard = key;
              }
            });
          },
          onLongPress: isLocked
              ? null
              : onLongPress, // Запрещаем long press, если анимация заблокирована
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
              _updateSettings();
            });
          },
          activeColor: isWhiteNotifier.value ? Colors.grey : Colors.white,
          inactiveColor: colors.textColor.withOpacity(0.3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ChatPreview(
            messageCornerRadius: 1,
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
                      _updateSettings();
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
                      _updateSettings();
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

  Widget _buildDivider(
      {required bool startFromLeft, required AppColors colors}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(
        color: colors.textColor.withOpacity(0.3),
        thickness: 1,
        indent: startFromLeft ? 0 : 50,
        endIndent: startFromLeft ? 50 : 0,
      ),
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
          'Поддержи авторов',
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
