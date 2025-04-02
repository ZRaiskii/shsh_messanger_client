import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/core/utils/AppColors.dart'; // Импортируем AppColors

import '../../../../app_state.dart';
import '../../../../core/app_settings.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../chat/presentation/widgets/typing_indicator.dart';
import '../../../settings/data/services/theme_manager.dart';
import '../../data/services/ChatStateManager.dart';
import '../../data/services/data_manager.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/lasr_message.dart';

class ChatListItem2 extends StatefulWidget {
  final Chat chat;
  final bool isSelected;
  final bool isPinned;
  final Function(String) onLongPress;
  final ChatStateManager stateManager;

  const ChatListItem2({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.isPinned,
    required this.onLongPress,
    required this.stateManager,
  });

  @override
  _ChatListItem2State createState() => _ChatListItem2State();
}

class _ChatListItem2State extends State<ChatListItem2> {
  Timer? _timer;
  late final ValueNotifier<bool> _isOnline;
  late final ValueNotifier<String> _userId;
  late final ValueNotifier<String> _recipientId;
  late final ValueNotifier<Map<String, dynamic>> _profileData;
  late final ValueNotifier<Message> _lastMessage;
  late final ValueNotifier<bool> _isLoading;
  late final ValueNotifier<String> _error;
  int _maxLines = 1;
  final DataManager _dataManager = DataManager();
  bool _showMessageCounter = true;

  int _typingDotsCount = 3; // Количество точек
  Timer? _typingDotsTimer; // Таймер для анимации точек

  @override
  void initState() {
    super.initState();
    // Получаем ValueNotifier для текущего чата
    _isOnline = widget.stateManager.getIsOnline(widget.chat.id);
    _userId = widget.stateManager.getUserId(widget.chat.id);
    _recipientId = widget.stateManager.getRecipientId(widget.chat.id);
    _profileData = widget.stateManager.getProfileData(widget.chat.id);
    _lastMessage = widget.stateManager.getLastMessage(widget.chat.id);
    _isLoading = widget.stateManager.getIsLoading(widget.chat.id);
    _error = widget.stateManager.getError(widget.chat.id);

    // _startTypingDotsAnimation();

    _loadShowMessageCounterPreference();
    _startTimer();
    _loadChatListType();
    _initializeData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Освобождаем ресурсы, когда элемент больше не отображается 1q2w3e4r5t6y.
    // widget.stateManager.disposeNotifier(widget.chat.id);
    _typingDotsTimer?.cancel();
    super.dispose();
  }

  void _startTypingDotsAnimation() {
    _typingDotsTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _typingDotsCount =
            (_typingDotsCount % 3) + 1; // Циклическое изменение от 1 до 3
      });
    });
  }

  void _startTimer() {
    _updateUserStatus();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateUserStatus();
      _checkForUpdates();
    });
  }

  Future<void> _initializeData() async {
    await _loadCachedData();
    await _loadServerData();
  }

  Future<void> _loadCachedData() async {
    try {
      final data = await _dataManager.initializeChatData(widget.chat);
      if (!mounted) return; // Проверяем, что виджет все еще "живой"

      // Проверяем mounted перед каждым обновлением ValueNotifier
      if (mounted) _userId.value = data['userId'];
      if (mounted) _recipientId.value = data['recipientId'];
      if (mounted) _profileData.value = data['profileData'];
      if (mounted) _lastMessage.value = data['lastMessage'];
      if (mounted) _isLoading.value = false;
    } catch (e) {
      if (!mounted) return; // Проверяем, что виджет все еще "живой"

      // Логируем ошибку (опционально)
      // print('Ошибка при загрузке данных: $e');

      // Повторная загрузка через 1.5 секунды
      await Future.delayed(Duration(milliseconds: 1500));

      // Проверяем mounted перед повторной загрузкой
      if (mounted) {
        _loadCachedData(); // Повторный вызов
      }
    }
  }

  Future<void> _loadShowMessageCounterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showMessageCounter = prefs.getBool('show_message_counter') ?? true;
    });
  }

  Future<void> _loadServerData() async {
    try {
      final Map<String, dynamic> data =
          await _dataManager.initializeChatData(widget.chat);
      final Map<String, dynamic> profileData =
          Map<String, dynamic>.from(data['profileData']);
      final Map<String, dynamic> lastMessageData = data['lastMessage'].toJson();
      if (_profileData.value != profileData ||
          _lastMessage.value != LastMessage.fromJson(lastMessageData)) {
        _profileData.value = profileData;
        _lastMessage.value = Message.fromJson(lastMessageData);
      }
    } catch (e) {
      print('Error loading server data: $e');
    }
  }

  Future<void> _updateUserStatus() async {
    final recipientId = _recipientId.value;
    if (mounted) {
      try {
        final status = await _dataManager.getUserStatus(recipientId);
        final isOnline = status['status'] == 'online';
        if (mounted && _isOnline.value != isOnline) {
          _isOnline.value = isOnline;
        }
      } catch (e) {
        if (mounted) {
          _isOnline.value = false;
        }
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final data = await _dataManager.initializeChatData(widget.chat);
      _profileData.value = data['profileData'];
      _lastMessage.value = data['lastMessage'] ??
          Message(
            id: "",
            chatId: "",
            recipientId: "",
            content: "Нет сообщений",
            timestamp: DateTime(1970),
            senderId: "",
            status: "FAILED",
          );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadChatListType() async {
    final prefs = await SharedPreferences.getInstance();
    final chatListType = prefs.getString('chat_list_type') ?? 'two_line';
    setState(() {
      _maxLines = chatListType == 'two_line' ? 1 : 2;
    });
  }

  void _openChatPage(BuildContext context, String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      try {
        final userMap = json.decode(cachedUser) as Map<String, dynamic>;
        final userId = UserModel.fromJson(userMap).id;
        if (userId != null) {
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
                chatId: chatId,
                userId: userId,
                recipientId: _recipientId.value,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;

                final tween = Tween(begin: begin, end: end);
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: curve,
                );

                return SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: child,
                );
              },
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Упс...')),
          );
        }
      } catch (e) {
        print('Error decoding cached user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Упс...')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Упс...')),
      );
    }
  }

  bool get isFavoriteChat {
    return _userId.value != null &&
        widget.chat.user1Id == _userId.value &&
        widget.chat.user2Id == _userId.value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return _buildLoadingState(colors);
        } else if (_error.value.isNotEmpty) {
          return _buildErrorState(colors);
        } else {
          // Проверяем настройку SwipeChat
          if (AppSettings.swipeAction == "Удалить") {
            return Dismissible(
              key: Key(widget.chat.id), // Уникальный ключ для каждого элемента
              direction: DismissDirection.startToEnd, // Только свайп вправо
              dismissThresholds: {
                DismissDirection.startToEnd: 0.7, // Порог в 70%
              },
              confirmDismiss: (direction) async {
                // Показываем диалог подтверждения удаления
                final bool? confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Подтверждение удаления'),
                      content: Text('Вы точно хотите удалить этот чат?'),
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
                return confirmDelete ?? false;
              },
              onDismissed: (direction) async {
                // Удаляем чат после подтверждения
                try {
                  await _dataManager.deleteChat(widget.chat.id);
                  // Обновляем список чатов
                  // _loadChats(await _loadUserId());
                } catch (e) {
                  print('Ошибка при удалении чата: $e');
                }
              },
              background: Container(
                color: colors.backgroundColor, // Цвет фона при свайпе
                alignment:
                    Alignment.centerLeft, // Выравниваем иконку удаления слева
                padding: EdgeInsets.only(left: 20.0),
                child: Icon(
                  Icons.delete,
                  color: isWhiteNotifier.value ? Colors.black : Colors.white,
                ),
              ),
              child: _buildChatItem(colors),
            );
          } else {
            // Если SwipeChat == "Нет", отображаем чат без Dismissible
            return _buildChatItem(colors);
          }
        }
      },
    );
  }

  Widget _buildLoadingState(AppColors colors) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _profileData,
      builder: (context, profileData, child) {
        if (profileData.isEmpty) {
          return _buildPlaceholder(colors);
        } else {
          return _buildChatItemContent(colors, profileData);
        }
      },
    );
  }

  Widget _buildErrorState(AppColors colors) {
    return GestureDetector(
      onLongPress: () => widget.onLongPress(widget.chat.id),
      child: Container(
        color:
            widget.isSelected ? Colors.blue.withOpacity(0.3) : colors.cardColor,
        child: ListTile(
          title: Text(
            'Ошибка: ${_error.value}',
            style: TextStyle(color: colors.textColor),
          ),
          subtitle: Text(
            widget.chat.email,
            style: TextStyle(color: colors.textColor),
          ),
          trailing: _buildUnreadMessagesIndicator(
              widget.chat.notRead, null, isFavoriteChat),
        ),
      ),
    );
  }

  Widget _buildChatItem(AppColors colors) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _profileData,
      builder: (context, profileData, child) {
        if (profileData.isEmpty) {
          return _buildPlaceholder(colors);
        } else {
          return _buildChatItemContent(colors, profileData);
        }
      },
    );
  }

  Widget _buildPlaceholder(AppColors colors) {
    return GestureDetector(
      onLongPress: () => widget.onLongPress(widget.chat.id),
      child: Container(
        color:
            widget.isSelected ? Colors.blue.withOpacity(0.3) : colors.cardColor,
        child: ListTile(
          subtitle: Text(
            widget.chat.email,
            style: TextStyle(color: colors.textColor),
          ),
          trailing: Icon(
            Icons.chat_bubble_outline,
            color: colors.iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildChatItemContent(
      AppColors colors, Map<String, dynamic> profileData) {
    final username = profileData['username'] ?? '';
    final avatarUrl = profileData['avatarUrl'] ?? '';
    final nicknameEmoji = profileData['nicknameEmoji'] ?? '';
    final isPremium = profileData['premium'] ?? false;

    // Проверяем, является ли nicknameEmoji Lottie-анимацией
    final bool isLottieEmoji = nicknameEmoji.startsWith('assets/');

    // Проверяем, является ли сообщение Lottie-анимацией
    final bool isLottieMessage =
        _lastMessage.value.content.startsWith('::animation_emoji/');

    return GestureDetector(
      onLongPress: () => widget.onLongPress(widget.chat.id),
      child: Container(
        color:
            widget.isSelected ? Colors.blue.withOpacity(0.3) : colors.cardColor,
        child: ListTile(
          leading: _buildAvatar(colors, avatarUrl, username),
          title: Row(
            children: [
              Text(
                isFavoriteChat ? 'Избранное' : username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              if (isPremium && nicknameEmoji.isNotEmpty && !isFavoriteChat)
                GestureDetector(
                  onTap: () {},
                  child: isLottieEmoji
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: Lottie.asset(
                            nicknameEmoji,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Text(
                          nicknameEmoji,
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.textColor,
                          ),
                        ),
                ),
            ],
          ),
          subtitle: ValueListenableBuilder<Map<String, Map<String, bool>>>(
            valueListenable: AppState().typingStatusNotifier,
            builder: (context, typingStatus, child) {
              final isTyping =
                  typingStatus[widget.chat.id]?[_recipientId.value] ?? true;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !isTyping
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: TypingIndicator(
                          isTyping: isTyping,
                          textColor: colors.primaryColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : isLottieMessage
                        ? Align(
                            alignment: Alignment
                                .centerLeft, // Выравниваем по левому краю
                            child: SizedBox(
                              width: 50, // Уменьшаем ширину
                              height: 50, // Уменьшаем высоту
                              child: Lottie.asset(
                                _lastMessage.value.content
                                    .replaceFirst('::animation_emoji/', '')
                                    .replaceAll('::', ''),
                                fit: BoxFit
                                    .contain, // Подгоняем анимацию под размер
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment
                                .centerLeft, // Выравниваем по левому краю
                            child: RichText(
                              text: TextSpan(
                                children: _formatMessageContent(
                                  _lastMessage.value.content,
                                  _lastMessage.value.senderId,
                                  _userId.value,
                                ),
                                style: TextStyle(color: colors.textColor),
                              ),
                              maxLines: _maxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
              );
            },
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Время и статус прочтения в одной строке
              Row(
                mainAxisSize: MainAxisSize.min, // Минимальная ширина
                children: [
                  Text(
                    !isFavoriteChat
                        ? _formatTime(_lastMessage.value.timestamp)
                        : "", // Форматируем время
                    style: TextStyle(
                      color: colors.textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4), // Отступ между временем и иконкой
                  if (_lastMessage.value.senderId == _userId.value &&
                      !isFavoriteChat)
                    _lastMessage.value.status == "FAILED"
                        ? Icon(
                            Icons.sms_failed,
                            size: 16.0,
                            color: Colors.red,
                          )
                        : Icon(
                            Icons.done_all,
                            size: 16.0,
                            color: _lastMessage.value.status == "READ"
                                ? const Color.fromARGB(255, 0, 14, 206)
                                : Colors.grey,
                          ),
                ],
              ),
              // Счётчик непрочитанных сообщений
              if (widget.chat.notRead > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4), // Отступ сверху
                  child: _buildUnreadMessagesIndicator(
                      widget.chat.notRead, null, isFavoriteChat),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4), // Отступ сверху
                  child: _buildUnreadMessagesIndicator(
                      1, Colors.transparent, isFavoriteChat),
                )
            ],
          ),
          onTap: () {
            if (_dataManager.isSelectedNotifier.value.isNotEmpty) {
              widget.onLongPress(widget.chat.id);
            } else {
              _openChatPage(context, widget.chat.id);
            }
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final localTimestamp = timestamp.add(Duration(hours: 3));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    if (localTimestamp.isAfter(today)) {
      return '${localTimestamp.hour.toString().padLeft(2, '0')}:${localTimestamp.minute.toString().padLeft(2, '0')}';
    } else if (localTimestamp.isAfter(weekStart)) {
      switch (localTimestamp.weekday) {
        case 1:
          return 'Пн';
        case 2:
          return 'Вт';
        case 3:
          return 'Ср';
        case 4:
          return 'Чт';
        case 5:
          return 'Пт';
        case 6:
          return 'Сб';
        case 7:
          return 'Вс';
        default:
          return '';
      }
    } else {
      return '${localTimestamp.day.toString().padLeft(2, '0')}.${localTimestamp.month.toString().padLeft(2, '0')}.${localTimestamp.year}';
    }
  }

  Widget _buildAvatar(AppColors colors, String avatarUrl, String username) {
    if (isFavoriteChat) {
      return CircleAvatar(
        backgroundColor: colors.backgroundColor,
        radius: 24,
        child: Icon(
          Icons.star,
          color: colors.primaryColor,
          size: 30,
        ),
      );
    }

    return Stack(
      children: [
        if (avatarUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: avatarUrl,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              backgroundImage: imageProvider,
              backgroundColor: colors.backgroundColor,
              radius: 24,
            ),
            placeholder: (context, url) => CircleAvatar(
              backgroundColor: colors.backgroundColor,
              radius: 24,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '',
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 18,
                ),
              ),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              backgroundColor: colors.backgroundColor,
              radius: 24,
              child: Icon(
                Icons.error,
                color: colors.textColor,
              ),
            ),
          ),
        if (avatarUrl.isEmpty)
          CircleAvatar(
            backgroundColor: colors.backgroundColor,
            radius: 24,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isOnline,
            builder: (context, isOnline, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.backgroundColor,
                    width: 2,
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.isPinned)
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              Icons.push_pin,
              size: 16,
              color: colors.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildUnreadMessagesIndicator(
      int notReadCount, Color? color, bool isFavorite) {
    if (AppSettings.showMessageCounter && notReadCount > 0 && !isFavorite) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: color ?? Colors.grey.withOpacity(0.5),
        child: Text(
          notReadCount > 99 ? '99+' : notReadCount.toString(),
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  List<TextSpan> _formatMessageContent(
      String content, String senderId, String userId) {
    final RegExp urlRegExp = RegExp(r'https?://[^\s]+');
    final RegExp codeBlockRegex =
        RegExp(r'```(\w+)?\s*([\s\S]+?)```', dotAll: true);
    final RegExp tagRegex = RegExp(r'<(/?[^>]+)>');

    content = content.replaceAll(codeBlockRegex, '');

    final Iterable<Match> matches = urlRegExp.allMatches(content);
    List<TextSpan> textSpans = [];
    int lastIndex = 0;

    if (senderId == userId) {
      textSpans.add(TextSpan(
        text: 'Вы: ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ));
    }

    for (Match match in matches) {
      if (lastIndex < match.start) {
        final String textPart = content.substring(lastIndex, match.start);
        textSpans.addAll(_parseTextContent(textPart));
      }
      textSpans.add(
        TextSpan(
          text: 'фотография',
          style: TextStyle(
            color: Colors.lightBlue,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final String remainingText = content.substring(lastIndex);
      textSpans.addAll(_parseTextContent(remainingText));
    }

    return textSpans;
  }

  List<TextSpan> _parseTextContent(String content) {
    final List<TextSpan> spans = [];
    final RegExp tagRegex = RegExp(r'<(/?[^>]+)>');
    final List<String> parts = content.split(tagRegex);
    final List<RegExpMatch> matches = tagRegex.allMatches(content).toList();

    for (int i = 0; i < parts.length; i++) {
      if (i < matches.length) {
        final String tag = matches[i].group(0)!;
        if (tag == '<b>' || tag == '<strong>') {
          spans.add(TextSpan(
              text: parts[i], style: TextStyle(fontWeight: FontWeight.bold)));
        } else if (tag == '</b>' || tag == '</strong>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<i>' || tag == '<em>') {
          spans.add(TextSpan(
              text: parts[i], style: TextStyle(fontStyle: FontStyle.italic)));
        } else if (tag == '</i>' || tag == '</em>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<del>' || tag == '<s>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(decoration: TextDecoration.lineThrough)));
        } else if (tag == '</del>' || tag == '</s>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<u>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(decoration: TextDecoration.underline)));
        } else if (tag == '</u>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<small>') {
          spans.add(TextSpan(text: parts[i], style: TextStyle(fontSize: 10)));
        } else if (tag == '</small>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<sub>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(fontFeatures: [FontFeature.subscripts()])));
        } else if (tag == '</sub>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<sup>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(fontFeatures: [FontFeature.superscripts()])));
        } else if (tag == '</sup>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<ins>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(decoration: TextDecoration.underline)));
        } else if (tag == '</ins>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<mark>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(backgroundColor: Colors.yellow)));
        } else if (tag == '</mark>') {
          spans.add(TextSpan(text: parts[i]));
        } else {
          spans.add(TextSpan(text: parts[i]));
        }
      } else {
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return spans;
  }
}
