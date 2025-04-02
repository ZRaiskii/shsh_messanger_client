// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/utils/constants.dart';
import 'package:shsh_social/core/utils/gesture_manager.dart';
import 'package:shsh_social/features/auth/data/models/user_model.dart';
import 'package:shsh_social/features/chat/data/services/chat_state_manager.dart';
import 'package:shsh_social/features/chat/data/services/stomp_client.dart';
import 'package:shsh_social/features/chat/domain/entities/message.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shsh_social/features/chat/presentation/widgets/code_block_widget.dart';
import 'dart:io';

import 'package:shsh_social/features/chat/presentation/widgets/full_screen_image_widget.dart';
import 'package:shsh_social/features/chat/presentation/widgets/single_play_lottie.dart';

import '../../../../core/app_settings.dart';
import 'package:lottie/lottie.dart';

import 'parent_message_widget.dart';
import 'photo_message_widget.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final String userId;
  final bool isRead;
  final Message? parentMessage;
  final VoidCallback onReply;
  final VoidCallback onSendMessage;
  final VoidCallback onEditMessage;
  final VoidCallback onRepeat;
  final VoidCallback onReading;
  final VoidCallback onTapReply;
  final ValueNotifier<String> messageStatusNotifier;

  const MessageBubble({
    super.key,
    required this.message,
    required this.userId,
    required this.isRead,
    this.parentMessage,
    required this.onReply,
    required this.onSendMessage,
    required this.onEditMessage,
    required this.onRepeat,
    required this.onReading,
    required this.onTapReply,
    required this.messageStatusNotifier,
  });

  @override
  MessageBubbleState createState() => MessageBubbleState();
}

class MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late bool _isSelected;

  final ValueNotifier<String?> _senderNameNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<Message?> _parentMessageNotifier =
      ValueNotifier<Message?>(null);
  double _dragExtent = 0.0;
  double _messageTextSize = 16.0;
  Offset? _tapPosition;
  double _messageCornerRadius = 8.0;
  Future<String>? _userNameFuture;
  late Animation<double> _opacityAnimation;
  late AnimationController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isSelected = ChatStateManager.instance.selectedMessages.value
        .contains(widget.message.id);
    ChatStateManager.instance.selectedMessages.addListener(_updateSelection);
    _loadMessageTextSize();
    _loadMessageCornerRadius();
    _fetchSenderName();
    _fetchParentMessage();
    _initializeUserNameFuture();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    widget.onReading();
  }

  @override
  void dispose() {
    ChatStateManager.instance.selectedMessages.removeListener(_updateSelection);

    super.dispose();
  }

  void _initializeUserNameFuture() {
    if (widget.message.parentMessageId != null &&
        widget.message.parentMessageId!.isNotEmpty) {
      _userNameFuture = _fetchUserName();
    }
  }

  Future<String> _fetchUserName() async {
    final parentMessage =
        await _fetchParentMessageFromServer(widget.message.parentMessageId!);
    if (parentMessage != null) {
      _parentMessageNotifier.value = parentMessage;
      return getUserName(parentMessage.senderId);
    }
    return "";
  }

  void _updateSelection() {
    if (mounted) {
      setState(() {
        _isSelected = ChatStateManager.instance.selectedMessages.value
            .contains(widget.message.id);
      });
    }
  }

  Future<void> _loadMessageCornerRadius() async {
    final prefs = await SharedPreferences.getInstance();
    final double? savedCornerRadius = prefs.getDouble('message_corner_radius');
    if (savedCornerRadius != null && mounted) {
      setState(() {
        _messageCornerRadius = savedCornerRadius;
      });
    }
  }

  bool isPhotoUrl(String text) {
    return text.startsWith('http') &&
        (text.endsWith('.jpg') ||
            text.endsWith('.png') ||
            text.endsWith('.jpeg'));
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

  void _forwardMessage(BuildContext context) {
    widget.onSendMessage();
  }

  Future<void> _loadMessageTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    final double? savedTextSize = prefs.getDouble('message_text_size');
    if (savedTextSize != null && mounted) {
      setState(() {
        _messageTextSize = savedTextSize;
      });
    }
  }

  Future<void> _fetchSenderName() async {
    if (widget.parentMessage != null &&
        widget.parentMessage!.senderId.isNotEmpty) {
      String? senderName = await getUserName(widget.parentMessage!.senderId);
      _senderNameNotifier.value = senderName;
    }
  }

  Future<Message?> _fetchParentMessageFromServer(String parentMessageId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/messages/$parentMessageId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final messageData = json.decode(utf8.decode(response.bodyBytes));
      final parentMessage = Message.fromJson(messageData);
      return parentMessage;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<void> _fetchParentMessage() async {
    if (widget.message.parentMessageId != null &&
        widget.message.parentMessageId!.isNotEmpty) {
      final cachedParentMessage =
          await _getCachedParentMessage(widget.message.parentMessageId!);
      if (cachedParentMessage != null) {
        _parentMessageNotifier.value = cachedParentMessage;
      }

      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          final parentMessage = await _fetchParentMessageFromServer(
              widget.message.parentMessageId!);
          if (parentMessage != null) {
            _parentMessageNotifier.value = parentMessage;
            await _cacheParentMessage(
                widget.message.parentMessageId!, parentMessage);
          }
        }
      } on SocketException catch (_) {
        print('Нет доступа к интернету. Данные загружены из кеша.');
      } catch (e) {
        print('Ошибка загрузки родительского сообщения: $e');
      }
    }
  }

  Future<void> _cacheParentMessage(
      String parentMessageId, Message parentMessage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_parent_message_$parentMessageId',
        json.encode(parentMessage.toJson()));
  }

  Future<Message?> _getCachedParentMessage(String parentMessageId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedMessage =
        prefs.getString('cached_parent_message_$parentMessageId');
    if (cachedMessage != null) {
      return Message.fromJson(json.decode(cachedMessage));
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadParentMessageData() async {
    if (widget.message.parentMessageId != null &&
        widget.message.parentMessageId!.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedData =
          prefs.getString(widget.message.parentMessageId!);

      if (cachedData != null) {
        final Map<String, dynamic> cachedMap = jsonDecode(cachedData);
        return {
          'parentMessage': cachedMap['parentMessage'],
          'senderName': cachedMap['senderName'],
        };
      } else {
        final parentMessage = await _fetchParentMessageFromServer(
            widget.message.parentMessageId!);
        if (parentMessage != null) {
          final senderName = await getUserName(parentMessage.senderId);

          final Map<String, dynamic> dataToCache = {
            'parentMessage': parentMessage,
            'senderName': senderName,
          };
          prefs.setString(
              widget.message.parentMessageId!, jsonEncode(dataToCache));

          return dataToCache;
        }
      }
    }
    return {
      'parentMessage': null,
      'senderName': null,
    };
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final List<PopupMenuEntry<dynamic>> items = [
      if (widget.message.isEdited!)
        PopupMenuItem<dynamic>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Изменено: ${formatMessageTime(widget.message.editedAt!)}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      if (widget.message.isEdited!) PopupMenuDivider(),

      PopupMenuItem<dynamic>(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Копировать'),
          ],
        ),
      ),
      PopupMenuItem<dynamic>(
        value: 'reply',
        child: Row(
          children: [
            Icon(Icons.reply, size: 20),
            SizedBox(width: 8),
            Text('Ответить'),
          ],
        ),
      ),
      PopupMenuItem<dynamic>(
        value: 'forward',
        child: Row(
          children: [
            Icon(Icons.forward, size: 20),
            SizedBox(width: 8),
            Text('Переслать'),
          ],
        ),
      ),
      if (widget.message.senderId == widget.userId &&
          !isPhotoUrl(widget.message.content) &&
          !widget.message.content.startsWith('::animation_emoji/'))
        PopupMenuItem<dynamic>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Изменить'),
            ],
          ),
        ),
      if (widget.message.status == "FAILED")
        PopupMenuItem<dynamic>(
          value: 'repeat',
          child: Row(
            children: [
              Icon(Icons.repeat, size: 20),
              SizedBox(width: 8),
              Text('Повторить'),
            ],
          ),
        ),
      // PopupMenuDivider(), // Разделитель перед удалением
      // PopupMenuItem<dynamic>(
      //   value: 'delete',
      //   child: Row(
      //     children: [
      //       Icon(Icons.delete, size: 20, color: Colors.red),
      //       SizedBox(width: 8),
      //       Text(
      //         'Удалить',
      //         style: TextStyle(color: Colors.red),
      //       ),
      //     ],
      //   ),
      // ),
    ];

    showMenu<dynamic>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          position,
          position.translate(1, 1),
        ),
        Offset.zero & overlay.size,
      ),
      items: items,
    ).then((value) {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: widget.message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Текст скопирован')),
        );
      } else if (value == 'reply') {
        widget.onReply();
      } else if (value == 'forward') {
        _forwardMessage(context);
      } else if (value == 'edit') {
        widget.onEditMessage();
      } else if (value == 'repeat') {
        widget.onRepeat();
      } else if (value == 'delete') {}
    });
  }

  void _checkCondition() {
    final isDelaySelected =
        ChatStateManager.instance.isSelectedDelay.value == widget.message.id;

    if (isDelaySelected) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  final Map<String, String> emojiMap = {
    '💯': '100.json',
    '⏰': 'alarm-clock.json',
    '😠': 'angry_emoji.json',
    '🔋': 'battary-full.json',
    '🪫': 'battary-low.json',
    '🎂': 'birthday-cake.json',
    '🩸': 'blood.json',
    '😊': 'blush.json',
    '💣': 'bomb.json',
    '🎳': 'bowling.json',
    '💔': 'broking-heart.json',
    '📟': 'byte_code_emoji.json',
    '🏁': 'chequered-flag.json',
    '🍻': 'chinking-beer-mugs.json',
    '👏': 'clap.json',
    '🤡': 'clown.json',
    '🥶': 'cold-face.json',
    '💥': 'collision.json',
    '🎉': 'confetti-ball.json',
    '❌': 'cross-mark.json',
    '🤞': 'crossed-fingers.json',
    '😢': 'crying_emoji.json',
    '🔮': 'crystal-ball.json',
    '🤬': 'cursing.json',
    '🎲': 'die.json',
    '😵': 'dizy-dace.json',
    '🤤': 'drool.json',
    '❗': 'exclamation.json',
    '😑': 'experssionless.json',
    '👀': 'eyes.json',
    '📄': 'file.py',
    '🔥': 'fire.json',
    '🙏': 'folded-hands.json',
    '⚙️': 'gear.json',
    '😬': 'grimacing.json',
    '😁': 'Grin.json',
    '😀': 'Grinning.json',
    '😇': 'halo.json',
    '😍': 'heart-eyes.json',
    '❤️': 'heart-face.json',
    '❤️': 'heart_emoji.json',
    '🥹': 'holding-back-tears.json',
    '🥵': 'hot-face.json',
    '🤗': 'hug-face.json',
    '😈': 'imp-smile.json',
    '😂': 'Joy.json',
    '😗': 'kiss.json',
    '😚': 'Kissing-closed-eyes.json',
    '😘': 'Kissing-heart.json',
    '😗': 'Kissing.json',
    '😂': 'laughing_emoji.json',
    '😂': 'Launghing.json',
    '💡': 'light-bulb.json',
    '😭': 'Loudly-crying.json',
    '🫠': 'melting.json',
    '🤯': 'mind-blown.json',
    '🤑': 'money-face.json',
    '💸': 'money-wings.json',
    '😶': 'mouth-none.json',
    '💪': 'muscle.json',
    '😐': 'neutral-face.json',
    '🎉': 'party-popper.json',
    '🥳': 'partying-face.json',
    '✏️': 'pencil.json',
    '😔': 'pensive.json',
    '🐷': 'pig.json',
    '🥺': 'pleading.json',
    '💩': 'poop.json',
    '❓': 'question.json',
    '🌈': 'rainbow.json',
    '🤨': 'raised-eyebrow.json',
    '😌': 'relieved.json',
    '💞': 'revolving-heart.json',
    '🤣': 'Rofl.json',
    '🙄': 'roling-eyes.json',
    '🫡': 'salute.json',
    '😱': 'screaming.json',
    '🤫': 'shushing-face.json',
    '💀': 'skull.json',
    '😴': 'sleep.json',
    '🎰': 'slot-machine.json',
    '😊': 'smile.json',
    '😃': 'smile_with_big_eyes.json',
    '😏': 'smirk.json',
    '⚽': 'soccer-bal.json',
    '✨': 'sparkles.json',
    '😛': 'stuck-out-tongue.json',
    '😎': 'subglasses-face.json',
    '🤒': 'thermometer-face.json',
    '🤔': 'thinking-face.json',
    '👎': 'thumbs-down.json',
    '👍': 'thumbs-up.json',
    '🙃': 'upside-down-face.json',
    '✌️': 'victory.json',
    '🤮': 'vomit.json',
    '☺️': 'warm-smile.json',
    '👋': 'wave.json',
    '😉': 'Wink.json',
    '😜': 'winky-tongue.json',
    '🥴': 'woozy.json',
    '🥱': 'yawn.json',
    '😋': 'yum.json',
    '🤪': 'zany-face.json',
    '🤐': 'zipper-face.json'
  };

  bool isLottieCheck(String content) {
    if (content.length == 2 && emojiMap.containsKey(content)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isSentByUser = widget.message.senderId == widget.userId;
    final bool isPhoto = _isImageUrl(widget.message.content);
    final bool isLottie = isLottieCheck(widget.message.content) ||
        widget.message.content.startsWith('::animation_emoji/');

    return ValueListenableBuilder<String?>(
        valueListenable: ChatStateManager.instance.isSelectedDelay,
        builder: (context, selectedDelayId, child) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _checkCondition());
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              if (GestureManager.isScreenSwiping.value) return;
              setState(() {
                _dragExtent += details.primaryDelta!;
                if (_dragExtent > 0) {
                  _dragExtent = 0;
                } else if (_dragExtent <
                    -MediaQuery.of(context).size.width * 0.5) {
                  _dragExtent = -MediaQuery.of(context).size.width * 0.5;
                }
              });
            },
            onHorizontalDragEnd: (details) {
              if (_dragExtent < -MediaQuery.of(context).size.width * 0.05) {
                widget.onReply();
              }
              setState(() {
                _dragExtent = 0;
              });
            },
            onTapDown: (TapDownDetails details) {
              _tapPosition = details.globalPosition;
            },
            onTap: () {
              final bool hasSelectedMessages =
                  ChatStateManager.instance.selectedMessages.value.isNotEmpty;
              if (hasSelectedMessages) {
                setState(() {
                  _isSelected = !_isSelected;
                  if (_isSelected) {
                    ChatStateManager.instance.selectedMessages.value = List
                        .from(ChatStateManager.instance.selectedMessages.value)
                      ..add(widget.message.id);
                  } else {
                    ChatStateManager.instance.selectedMessages.value = List
                        .from(ChatStateManager.instance.selectedMessages.value)
                      ..remove(widget.message.id);
                  }
                });
              } else {
                if (_tapPosition != null) {
                  _showContextMenu(context, _tapPosition!);
                }
              }
            },
            onLongPress: () {
              setState(() {
                _isSelected = !_isSelected;
                if (_isSelected) {
                  ChatStateManager.instance.selectedMessages.value = List.from(
                      ChatStateManager.instance.selectedMessages.value)
                    ..add(widget.message.id);
                } else {
                  ChatStateManager.instance.selectedMessages.value = List.from(
                      ChatStateManager.instance.selectedMessages.value)
                    ..remove(widget.message.id);
                }
              });
            },
            child: Container(
              width: double.infinity,
              child: Stack(
                children: [
                  if (_isSelected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                AppSettings.messageCornerRadius),
                          ),
                        ),
                      ),
                    ),
                  if (ChatStateManager.instance.isSelectedDelay.value ==
                      widget.message.id)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _opacityAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(
                                  _opacityAnimation.value,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSettings.messageCornerRadius,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Align(
                      alignment: isSentByUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(_dragExtent, 0),
                        child: IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 25.0,
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isLottie
                                    ? Colors.transparent
                                    : isSentByUser
                                        ? Colors.blue
                                        : Colors.grey[300],
                                borderRadius: BorderRadius.circular(
                                    AppSettings.messageCornerRadius),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 12.0),
                              child: Column(
                                crossAxisAlignment: isSentByUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.message.parentMessageId != null &&
                                      widget
                                          .message.parentMessageId!.isNotEmpty)
                                    ValueListenableBuilder<Message?>(
                                      valueListenable: _parentMessageNotifier,
                                      builder: (context, parentMessage, child) {
                                        if (parentMessage != null) {
                                          return FutureBuilder<String>(
                                            future: _userNameFuture,
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return CircularProgressIndicator();
                                              } else if (snapshot.hasError) {
                                                return Text("Ошибка загрузки");
                                              } else if (snapshot.hasData) {
                                                if (widget.message.chatId ==
                                                    parentMessage.chatId) {
                                                  return ParentMessageWidget(
                                                    parentMessage:
                                                        parentMessage,
                                                    senderName: snapshot.data!,
                                                    onTapReply:
                                                        widget.onTapReply,
                                                  );
                                                }
                                                return ParentMessageWidget(
                                                  parentMessage: parentMessage,
                                                  senderName: snapshot.data!,
                                                  onTapReply: null,
                                                );
                                              } else {
                                                return Text("Нет данных");
                                              }
                                            },
                                          );
                                        } else {
                                          return Text("Нет данных");
                                        }
                                      },
                                    ),
                                  RepaintBoundary(
                                    child: Column(
                                      children: [
                                        if (isPhoto)
                                          PhotoMessageWidget(
                                              imageUrl: widget.message.content),
                                        if (!isPhoto) _buildTextMessageWidget(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatMessageTime(
                                            widget.message.timestamp),
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          color: isLottie
                                              ? Colors.grey
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.message.isEdited!)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.edit,
                                            size: 12.0,
                                            color: isLottie
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      if (isSentByUser)
                                        ValueListenableBuilder<String>(
                                          valueListenable:
                                              widget.messageStatusNotifier,
                                          builder: (context, status, child) {
                                            return status == "FAILED"
                                                ? Icon(
                                                    Icons.sms_failed,
                                                    size: 16.0,
                                                    color: Colors.red,
                                                  )
                                                : Icon(
                                                    Icons.done_all,
                                                    size: 16.0,
                                                    color: status == "READ"
                                                        ? const Color.fromARGB(
                                                            255, 0, 14, 206)
                                                        : Colors.grey,
                                                  );
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildParentMessageWidget() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadParentMessageData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            "Ошибка загрузки",
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        } else if (snapshot.hasData) {
          final parentMessage = snapshot.data!['parentMessage'];
          final senderName = snapshot.data!['senderName'];
          bool isParentPhoto = false;
          bool isParentLottie = false;

          if (parentMessage != null && senderName != null) {
            final String content = parentMessage is Message
                ? parentMessage.content
                : parentMessage["content"];

            // Проверяем, является ли сообщение изображением
            isParentPhoto = _isImageUrl(content);

            // Проверяем, является ли сообщение анимированным emoji (Lottie)
            isParentLottie = content.startsWith('::animation_emoji/');

            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6.0),
              ),
              padding: const EdgeInsets.all(6.0),
              margin: const EdgeInsets.only(bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 10.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Row(
                    children: [
                      Container(
                        width: 3.0,
                        height: 30.0,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 6.0),
                      if (isParentPhoto)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: CachedNetworkImage(
                            imageUrl: content,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                        )
                      else if (isParentLottie)
                        Lottie.asset(
                          content
                              .replaceFirst('::animation_emoji/', '')
                              .replaceAll('::', ''),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      else
                        Flexible(
                          child: Text(
                            content,
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Text(
              "Нет данных",
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }
        } else {
          return Text(
            "Нет данных",
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }
      },
    );
  }

  Widget _buildPhotoMessageWidget() {
    const double fixedPortraitWidth = 200.0;
    const double fixedPortraitHeight = 300.0;
    const double fixedLandscapeWidth = 300.0;
    const double fixedLandscapeHeight = 200.0;

    Future<Size> _getImageDimensions(String imageUrl) async {
      final Completer<Size> completer = Completer();
      final Image image = Image.network(imageUrl);

      image.image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          final Size size =
              Size(info.image.width.toDouble(), info.image.height.toDouble());
          completer.complete(size);
        }),
      );

      return completer.future;
    }

    return FutureBuilder<Size>(
      future: _getImageDimensions(widget.message.content),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 300,
            height: 300,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Icon(Icons.error);
        } else if (snapshot.hasData) {
          final Size imageSize = snapshot.data!;
          final bool isPortrait = imageSize.height > imageSize.width;

          return GestureDetector(
            onTap: () {
              _showImagePreview(context, widget.message.content);
            },
            child: CachedNetworkImage(
              imageUrl: widget.message.content,
              fit: BoxFit.cover,
              width: isPortrait ? fixedPortraitWidth : fixedLandscapeWidth,
              height: isPortrait ? fixedPortraitHeight : fixedLandscapeHeight,
              memCacheWidth: isPortrait
                  ? fixedPortraitWidth.toInt()
                  : fixedLandscapeWidth.toInt(),
              memCacheHeight: isPortrait
                  ? fixedPortraitHeight.toInt()
                  : fixedLandscapeHeight.toInt(),
              placeholder: (context, url) => Container(
                width: isPortrait ? fixedPortraitWidth : fixedLandscapeWidth,
                height: isPortrait ? fixedPortraitHeight : fixedLandscapeHeight,
                color: Colors.grey[300],
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fadeInDuration: Duration.zero, // Убираем анимацию загрузки
              fadeOutDuration: Duration.zero,
            ),
          );
        } else {
          return Container(); // Fallback in case of unexpected state
        }
      },
    );
  }

  Widget _buildTextMessageWidget() {
    final String content = widget.message.content;
    if (content.startsWith('::animation_emoji/') || isLottieCheck(content)) {
      return _buildLottieMessage(content);
    } else {
      return _buildTextMessage(content);
    }
  }

  /// Метод для отображения анимированного emoji (Lottie)
  Widget _buildLottieMessage(String content) {
    final emojiPath =
        content.replaceFirst('::animation_emoji/', '').replaceAll('::', '');

    final assetPath = content.startsWith("::animation_emoji/")
        ? emojiPath
        : 'assets/${emojiMap[content]}';

    return ReusableLottie(
      assetPath: assetPath,
      width: 100,
      height: 100,
    );
  }

  Widget _buildTextMessage(String content) {
    final List<InlineSpan> spans = _parseMessageContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: spans,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.black,
              fontSize: AppSettings.messageTextSize,
              fontFamily: "NotoColorEmoji",
            ),
          ),
        ),
        for (var span in spans)
          if (span.style?.backgroundColor == Colors.grey[200])
            CodeBlockWidget(code: span.toPlainText(), language: 'Language'),
      ],
    );
  }

  Widget _buildMessageTimeWidget(bool isSentByUser, bool isRead) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatMessageTime(widget.message.timestamp),
          style: TextStyle(
            fontSize: 10.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isSentByUser) // Иконка только для отправленных сообщений
          Icon(
            Icons.done_all,
            size: 16.0,
            color: isRead ? const Color.fromARGB(255, 0, 14, 206) : Colors.grey,
          ),
      ],
    );
  }

  Widget _buildImageWidget(dynamic imageSource) {
    return FutureBuilder<Size>(
      future: _getImageSize(imageSource),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Icon(Icons.error);
        } else if (snapshot.hasData) {
          final size = snapshot.data!;
          final double aspectRatio = size.width / size.height;

          // Определение ориентации изображения
          if (aspectRatio == 1) {
            // Квадратное изображение
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _buildImage(imageSource, 300, 300),
            );
          } else if (aspectRatio < 1) {
            // Портретное изображение
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _buildImage(imageSource, 300, 350),
            );
          } else {
            // Ландшафтное изображение
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _buildImage(imageSource, 400, 350),
            );
          }
        } else {
          return Icon(Icons.error);
        }
      },
    );
  }

  Widget _buildImage(dynamic imageSource, double width, double height) {
    if (imageSource is File) {
      return Image.file(
        imageSource,
        fit: BoxFit.cover,
        width: width,
        height: height,
      );
    } else if (imageSource is String) {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: width,
        height: height,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Icon(Icons.error),
      );
    } else {
      return Icon(Icons.error);
    }
  }

  Future<Size> _getImageSize(dynamic imageSource) async {
    if (imageSource is File) {
      final decodedImage =
          await decodeImageFromList(imageSource.readAsBytesSync());
      return Size(
          decodedImage.width.toDouble(), decodedImage.height.toDouble());
    } else if (imageSource is String) {
      final response = await http.get(Uri.parse(imageSource));
      final decodedImage = await decodeImageFromList(response.bodyBytes);
      return Size(
          decodedImage.width.toDouble(), decodedImage.height.toDouble());
    } else {
      throw Exception("Unsupported image source type");
    }
  }

  bool _isImageUrl(String url) {
    return url.startsWith('http') &&
        (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png'));
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageView(
          imageUrl: imageUrl,
          onClose: () {
            if (mounted) {
              setState(() {
                // _isImageViewOpen = false; // Unused variable
              });
            }
          },
          timestamp: DateTime.now(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.ease;

          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          return FadeTransition(
            opacity: tween.animate(curvedAnimation),
            child: child,
          );
        },
      ),
    );
  }

  Future<File?> _loadImageFromCache(String imageUrl) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final fileName = imageUrl.split('/').last;
    final file = File('${documentDirectory.path}/$fileName');

    if (await file.exists()) {
      return file;
    } else {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        return null;
      }
    }
  }
}

String formatMessageTime(DateTime timestamp) {
  final int offsetInHours = DateTime.now().timeZoneOffset.inHours;

  final DateTime adjustedTimestamp =
      timestamp.add(Duration(hours: offsetInHours));

  return DateFormat('HH:mm').format(adjustedTimestamp);
}

List<InlineSpan> _parseMessageContent(String content) {
  final List<InlineSpan> spans = [];
  final RegExp codeBlockRegex =
      RegExp(r'```(\w+)?\s*([\s\S]+?)```', dotAll: true);
  final RegExp tagRegex = RegExp(r'<(/?[^>]+)>');

  // Разделяем содержимое на части, которые соответствуют блокам кода и обычному тексту
  final List<String> parts = content.split(codeBlockRegex);
  final List<RegExpMatch> codeMatches =
      codeBlockRegex.allMatches(content).toList();

  for (int i = 0; i < parts.length; i++) {
    if (i < codeMatches.length) {
      // Обрабатываем блоки кода
      final String? language = codeMatches[i].group(1);
      final String codeBlock = codeMatches[i].group(2)!;
      spans.add(WidgetSpan(
        child: CodeBlockWidget(code: codeBlock, language: language ?? ''),
      ));
    } else {
      // Обрабатываем обычный текст с HTML-подобными тегами
      final List<InlineSpan> textSpans = _parseTextContent(parts[i]);
      spans.addAll(textSpans);
    }
  }

  return spans;
}

List<InlineSpan> _parseTextContent(String content) {
  final List<InlineSpan> spans = [];
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
            text: parts[i], style: TextStyle(backgroundColor: Colors.yellow)));
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

Future<String> getUserName(String userId) async {
  if (userId.isEmpty) {
    print('User ID is empty');
    return "";
  }
  final cachedSenderName = await _getCachedSenderName(userId);
  if (cachedSenderName != null) {
    print('Using cached sender name: $cachedSenderName');
    return cachedSenderName;
  }

  final headers = await _getHeaders();
  try {
    final response = await http.get(
      Uri.parse(
          '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final userProfile = json.decode(utf8.decode(response.bodyBytes));
      final senderName = userProfile['username'];
      print('Sender name fetched from server: $senderName');
      await _cacheSenderName(userId, senderName);
      return senderName;
    } else {
      print('Server error: ${response.statusCode}');
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching sender name: $e');
  }
  return "";
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

Future<void> _cacheSenderName(String senderId, String senderName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cached_sender_name_$senderId', senderName);
}

Future<String?> _getCachedSenderName(String senderId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cached_sender_name_$senderId');
}
