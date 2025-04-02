// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/core/utils/DeviceRegistration.dart';
import 'package:vibration/vibration.dart';

import '../../../../app_state.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../../core/widgets/new_year/new_year_snowfall.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../mini_apps/presentation/mini_apps_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/data/services/theme_manager.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../data/services/ChatStateManager.dart';
import '../../data/services/data_manager.dart';
import '../../domain/entities/chat.dart';
import '../widgets/chat_list_item2.dart';
import '../widgets/search_bar.dart';
import 'qr_scanner_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0);
  Timer? _timer;
  bool _isLoadingChats = false;
  String? _backgroundImage;
  late PageController _pageController;
  final DataManager _dataManager = DataManager();
  String _selectedAnimation = "none"; // Выбранная анимация
  final ValueNotifier<List<String>> _pinnedChatsNotifier =
      ValueNotifier<List<String>>([]);
  bool _isSnackBarVisible = false;
  final ChatStateManager chatStateManager = ChatStateManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPinnedChats();
    _dataManager.onError = _showErrorNotification;

    _loadUserId().then((userId) async {
      DeviceRegistration.registerDevice(userId);
      var chats = await _dataManager.getChats(userId);
      _dataManager.syncManager.syncChatsWithServer(userId);
    });

    AppState().onMessageReceivedChats = _onNewMessageReceived;

    _startTimer();
    _pageController = PageController(initialPage: _selectedIndexNotifier.value);

    _loadSelectedAnimation();

    _initializeAsyncData();
  }

  Future<void> _initializeAsyncData() async {
    try {
      final userId = await _loadUserId();
      DeviceRegistration.registerDevice(userId);

      final chats = await _dataManager.getChats(userId);
      _dataManager.syncManager.syncChatsWithServer(userId);

      if (!Platform.isWindows) {
        final status = await GoogleApiAvailability.instance
            .checkGooglePlayServicesAvailability();

        if (status == GooglePlayServicesAvailability.success) {
          _setupNotificationHandlers();
          _handleInitialNotification();
          _checkPendingNotifications();
        }
      }
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  Future<void> _loadSelectedAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAnimation = prefs.getString('selected_animation') ?? "none";
    });
  }

  Future<void> _checkPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getString('pending_notification');
    if (pendingData != null && mounted) {
      final data = jsonDecode(pendingData) as Map<String, dynamic>;
      await _processNotificationData(data);
      await prefs.remove('pending_notification');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('POP');
    _loadBackgroundImage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _onLifeCycleChanged(state);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      _checkRefreshAndInternetStatus();
    });
  }

  Future<void> _loadPinnedChats() async {
    final pinnedChats = await _dataManager.getPinnedChats();
    _pinnedChatsNotifier.value = pinnedChats;
  }

  void _toggleChatSelection(String chatId) async {
    final selectedChats =
        List<String>.from(_dataManager.isSelectedNotifier.value);
    bool shouldVibrate = await Vibration.hasVibrator() ?? false;

    setState(() {
      if (selectedChats.contains(chatId)) {
        selectedChats.remove(chatId);
        if (shouldVibrate) {
          Vibration.vibrate(duration: 50);
        }
      } else {
        selectedChats.add(chatId);
        if (shouldVibrate) {
          Vibration.vibrate(duration: 100);
        }
      }
      _dataManager.isSelectedNotifier.value = selectedChats;
    });
  }

  void _pinSelectedChats() async {
    for (final chatId in _dataManager.isSelectedNotifier.value) {
      await _dataManager.pinChat(chatId);
    }
    _loadPinnedChats();
    _dataManager.isSelectedNotifier.value = [];
    _loadChats(await _loadUserId());
  }

  void _unpinSelectedChats() async {
    for (final chatId in _dataManager.isSelectedNotifier.value) {
      await _dataManager.unpinChat(chatId);
    }
    _loadPinnedChats();
    _dataManager.isSelectedNotifier.value = [];
    _loadChats(await _loadUserId());
  }

  void _checkRefreshAndInternetStatus() async {
    try {
      _loadChats(await _loadUserId());
      if (AppState().isRefresh!) {
        AppState().isRefresh = false;
        _loadUserId().then((userId) async {
          List<Chat> chats = await _dataManager.getChats(userId);
          _dataManager.syncManager.syncChatsWithServer(userId);
          _dataManager.updateChats(chats);
          AppState().onMessageReceivedChats = _onNewMessageReceived;
        });
      }
    } catch (e) {
      print("e: $e");
    }
  }

  Future<String> _loadUserId() async {
    return await _dataManager.loadUserId();
  }

  void _loadChats(String userId) async {
    if (_isLoadingChats) return;
    _isLoadingChats = true;

    try {
      List<Chat> chats = await _dataManager.getChats(userId);

      setState(() {});
    } catch (e) {
      print(e);
      final cachedChats = await _dataManager.getCachedChats();
      _updateChats(cachedChats ?? []);
    } finally {
      _isLoadingChats = false;
    }
  }

  void _updateChats(List<Chat> chats) {
    if (mounted) {
      if (_dataManager.chatsNotifier.value != chats) {
        _sortChats(chats);
        _dataManager.chatsNotifier.value = chats;
        setState(() {});
      }
    }
  }

  void _sortChats(List<Chat> chats) {
    chats.sort((a, b) {
      final aCreatedAt =
          a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreatedAt =
          b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreatedAt.compareTo(aCreatedAt);
    });
  }

  void _onItemTapped(int index) {
    _selectedIndexNotifier.value = index;
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _onNewMessageReceived(Message message) async {
    _dataManager.syncManager.dbHelper.insertMessage(message);

    final chatIndex = _dataManager.chatsNotifier.value
        .indexWhere((chat) => chat.id == message.chatId);
    if (chatIndex != -1) {
      final updatedChat = _dataManager.chatsNotifier.value[chatIndex]
          .copyWith(lastMessage: message);

      final newChats = List<Chat>.from(_dataManager.chatsNotifier.value);
      newChats[chatIndex] = updatedChat;
      _sortChats(newChats);

      _dataManager.chatsNotifier.value = newChats; // Обновляем ValueNotifier
    }
    _loadUserId().then((userId) async {
      List<Chat> chats = await _dataManager.getChats(userId);
      _dataManager.syncManager.syncChatsWithServer(userId);
      _dataManager.updateChats(chats);
    });
  }

  void _onLifeCycleChanged(AppLifecycleState state) async {
    _loadUserId().then((userId) {
      if (!_isLoadingChats && AppState().isRefresh!) {
        _loadChats(userId);
      }
    });
  }

  void _showErrorNotification(String message) {
    if (_isSnackBarVisible) {
      return;
    }

    _isSnackBarVisible = true;
  }

  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final backgroundImage = prefs.getString('background_image');
    setState(() {
      _backgroundImage = backgroundImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _selectedIndexNotifier.value = index;
            },
            children: [
              _buildChatList(colors),
              MiniAppsPage(),
              ProfilePage(userId: '0'),
              SettingsPage(),
            ],
          ),
          IgnorePointer(
            child: _buildSnowfall(),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _selectedIndexNotifier,
        builder: (context, selectedIndex, child) {
          return Container(
            color: colors.appBarColor,
            child: NavigationBar(
              backgroundColor: colors.cardColor,
              height: 55.0,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index),
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    Icons.chat_outlined,
                    color: colors.iconColor,
                  ),
                  selectedIcon: Icon(
                    Icons.chat,
                    color: colors.iconColor,
                  ),
                  label: 'Чаты',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.apps_outlined,
                    color: colors.iconColor,
                  ),
                  selectedIcon: Icon(
                    Icons.apps,
                    color: colors.iconColor,
                  ),
                  label: 'Приложения',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.person_outline,
                    color: colors.iconColor,
                  ),
                  selectedIcon: Icon(
                    Icons.person,
                    color: colors.iconColor,
                  ),
                  label: 'Профиль',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colors.iconColor,
                  ),
                  selectedIcon: Icon(
                    Icons.settings,
                    color: colors.iconColor,
                  ),
                  label: 'Настройки',
                ),
              ],
              labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    );
                  }
                  return TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  );
                },
              ),
              indicatorColor: Colors.transparent,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatList(AppColors colors) {
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              'Чаты',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _dataManager.isLoadingNotifier,
              builder: (context, isLoading, child) {
                return isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primaryColor,
                        ),
                      )
                    : SizedBox.shrink();
              },
            ),
          ],
        ),
        elevation: 0.0,
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            iconSize: 30.0,
            color: colors.iconColor,
            onPressed: () async {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(userId: await _loadUserId()),
              );
            },
          ),
          ValueListenableBuilder<List<String>>(
            valueListenable: _dataManager.isSelectedNotifier,
            builder: (context, selectedChats, child) {
              if (selectedChats.isNotEmpty) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: PopupMenuThemeData(
                      color: colors.backgroundColor,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colors.iconColor),
                    onSelected: (String value) {
                      if (value == 'pin') {
                        _pinSelectedChats();
                      } else if (value == 'unpin') {
                        _unpinSelectedChats();
                      } else if (value == 'scan_qr') {
                        _scanQRCode();
                      } else if (value == 'delete') {
                        _deleteSelectedChats();
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final isAnyChatPinned = selectedChats.any((chatId) =>
                          _pinnedChatsNotifier.value.contains(chatId));
                      return [
                        PopupMenuItem<String>(
                          value: 'scan_qr',
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: colors.iconColor),
                              SizedBox(width: 8),
                              Text(
                                'Сканировать QR-Code',
                                style: TextStyle(color: colors.textColor),
                              ),
                            ],
                          ),
                        ),
                        if (isAnyChatPinned)
                          PopupMenuItem<String>(
                            value: 'unpin',
                            child: Row(
                              children: [
                                Icon(Icons.push_pin_outlined,
                                    color: colors.iconColor),
                                SizedBox(width: 8),
                                Text(
                                  'Открепить чат',
                                  style: TextStyle(color: colors.textColor),
                                ),
                              ],
                            ),
                          ),
                        if (!isAnyChatPinned)
                          PopupMenuItem<String>(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(Icons.push_pin, color: colors.iconColor),
                                SizedBox(width: 8),
                                Text(
                                  'Закрепить чат',
                                  style: TextStyle(color: colors.textColor),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: colors.iconColor),
                              SizedBox(width: 8),
                              Text(
                                'Удалить',
                                style: TextStyle(color: colors.textColor),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                );
              } else {
                return Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: PopupMenuThemeData(
                      color: colors.backgroundColor,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colors.iconColor),
                    onSelected: (String value) {
                      if (value == 'scan_qr') {
                        _scanQRCode();
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'scan_qr',
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: colors.iconColor),
                              SizedBox(width: 8),
                              Text(
                                'Сканировать QR-Code',
                                style: TextStyle(color: colors.textColor),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<Chat>>(
                  valueListenable: _dataManager.chatsNotifier,
                  builder: (context, chats, child) {
                    return CustomScrollView(
                      children: [
                        ...chats
                            .where((chat) =>
                                _pinnedChatsNotifier.value.contains(chat.id))
                            .expand((chat) {
                          final index = chats.indexOf(chat);
                          return [
                            Container(
                              color: colors.backgroundColor,
                              child: ChatListItem2(
                                key: ValueKey(chat.id),
                                chat: chat,
                                isSelected: _dataManager
                                    .isSelectedNotifier.value
                                    .contains(chat.id),
                                isPinned: true,
                                onLongPress: _toggleChatSelection,
                                stateManager: chatStateManager,
                              ),
                            ),
                            if (index != chats.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 64.0),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: colors.dividerColor,
                                ),
                              ),
                          ];
                        }).toList(),

                        // Список остальных чатов
                        ...chats
                            .where((chat) =>
                                !_pinnedChatsNotifier.value.contains(chat.id))
                            .expand((chat) {
                          final index = chats.indexOf(chat);
                          return [
                            Container(
                              color: colors.backgroundColor,
                              child: ChatListItem2(
                                key: ValueKey(chat.id),
                                chat: chat,
                                isSelected: _dataManager
                                    .isSelectedNotifier.value
                                    .contains(chat.id),
                                isPinned: false,
                                onLongPress: _toggleChatSelection,
                                stateManager: chatStateManager,
                              ),
                            ),
                            if (index != chats.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 64.0),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: colors.dividerColor,
                                ),
                              ),
                          ];
                        }).toList(),

                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.dividerColor,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnowfall() {
    if (_selectedAnimation == "snowflakes" ||
        _selectedAnimation == "hearts" ||
        _selectedAnimation == "smileys") {
      return NewYearSnowfall(
        isPlaying: _selectedAnimation == "snowflakes" ||
            _selectedAnimation == "hearts" ||
            _selectedAnimation == "smileys",
        animationType: _selectedAnimation,
        child: Container(), // Пустой контейнер для анимации
      );
    }
    return Container();
  }

  void _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen()),
    );

    if (result != null) {
      print(result);
    }
  }

  void _setupNotificationHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
    });
  }

  void _handleInitialNotification() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && mounted) {
      _processNotificationData(initialMessage.data);
    }
  }

  void _handleNotification(RemoteMessage message) {
    if (mounted) {
      _processNotificationData(message.data);
    }
  }

  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    try {
      if (data['chatId'] == null || data['senderId'] == null) return;

      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('cached_user');
      if (cachedUser == null) return;

      final user = UserModel.fromJson(json.decode(cachedUser));
      if (user.id == null) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: data['chatId'].toString(),
            userId: user.id!,
            recipientId: data['senderId'].toString(),
          ),
        ),
      );
    } catch (e) {
      print('Error processing notification: $e');
    }
  }

  void _deleteSelectedChats() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение удаления'),
          content: Text('Вы точно хотите удалить выбранные чаты?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      for (final chatId in _dataManager.isSelectedNotifier.value) {
        try {
          await _dataManager.deleteChat(chatId);
        } catch (e) {
          print('Ошибка при удалении чата: $e');
        }
      }
      _dataManager.isSelectedNotifier.value = [];
      _loadChats(await _loadUserId());
    }
  }
}

class CustomScrollView extends StatelessWidget {
  final List<Widget> children;

  const CustomScrollView({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: children,
      ),
    );
  }
}
