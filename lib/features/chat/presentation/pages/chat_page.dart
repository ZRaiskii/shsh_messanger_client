import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/FCMManager.dart';
import '../../../../core/widgets/custom/swipe_back_wrapper.dart';
import '../../../../app_state.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../calls/presentation/pages/call_page.dart';
import '../../../calls/presentation/widgets/call_status_widget.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/models/photo_model.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/shared_preferences_singleton.dart';
import '../../data/services/stomp_client.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/fetch_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/profile_info.dart';
import '../../../main/data/services/data_manager.dart';
import '../../../main/domain/entities/chat.dart';
import '../../../main/presentation/widgets/chat_selection_page.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/widgets/profile_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:async';
import 'dart:io';
import '../../../../core/widgets/new_year/new_year_snowfall.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../../core/data_base_helper.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../settings/data/services/theme_manager.dart';
import 'package:lottie/lottie.dart';

import '../../data/services/chat_state_manager.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  final String? chatId;
  final String userId;
  final String recipientId;

  const ChatPage({
    this.chatId,
    required this.userId,
    required this.recipientId,
    super.key,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  final ChatStateManager _chatStateManager = ChatStateManager.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late WebSocketClientService _webSocketClientService;
  late AppLifecycleListener _lifeCycleListener;
  String recipientUserName = '';
  Profile? recipientProfile;
  bool isProfileOverlayVisible = false;
  Timer? _timer;
  bool _isLoadingMessages = false;
  String? _backgroundImage;
  String _selectedAnimation = "none";
  String? _chatId;
  bool _showScrollButton = false;

  int _typingDotsCount = 3;
  Timer? _typingDotsTimer;
  final ValueNotifier<String> _typingTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final Map<String, ValueNotifier<String>> _messageStatusNotifiers = {};
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();

    DataManager().syncManager.syncChatsWithServer(widget.userId);

    _chatId = widget.chatId;

    _webSocketClientService = WebSocketClientService.instance;
    AppState().currentChatId = widget.chatId;
    AppState().onMessageReceived = (message) {
      if (message.senderId == widget.userId ||
          message.senderId == widget.recipientId && _chatId == message.chatId) {
        _addMessage(message);
        _markMessagesAsRead([message.id], widget.chatId!);
      }
      _updateUserStatus();
    };

    AppState().removeMessageFromChat = (chatId, messageId) {
      _chatStateManager.messagesNotifier.value =
          List.from(_chatStateManager.messagesNotifier.value)
            ..removeWhere((message) => message.id == messageId);
      final dbHelper = DatabaseHelper();
      dbHelper.deleteMessage(messageId);
      _saveMessagesToCache(_chatStateManager.messagesNotifier.value);
    };

    AppState().messagesReadNotification = (messageIds, readerId, chatId) {
      handleMessagesRead(
        chatId,
        readerId,
        messageIds,
      );
    };

    AppState().updateMessageContent =
        (String messageId, String newContent, String editedAt) async {
      final messages = _chatStateManager.messagesNotifier.value;
      final index = messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        final updatedMessage = messages[index].copyWith(
          content: newContent,
          isEdited: true,
          editedAt: DateTime.parse(editedAt),
        );

        final dbHelper = DatabaseHelper();
        await dbHelper.updateMessage(updatedMessage);

        _chatStateManager.messagesNotifier.value = List.from(messages)
          ..[index] = updatedMessage;

        _saveMessagesToCache(_chatStateManager.messagesNotifier.value);
      }
    };
    _startTimer();
    _loadBackgroundImage();
    _loadProfileInfo();
    _loadSelectedAnimation();
    _loadMessagesFromServer();

    _lifeCycleListener = AppLifecycleListener(
      onStateChange: _onLifeCycleChanged,
    );
  }

  Future<void> _loadSelectedAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAnimation = prefs.getString('selected_animation') ?? "none";
    });
  }

  void _initializeMessageStatusNotifiers(List<Message> messages) {
    for (var message in messages) {
      _messageStatusNotifiers[message.id] = ValueNotifier(message.status);
    }
  }

  void _updateMessageStatus(String messageId, String newStatus) {
    if (mounted) {
      setState(() {
        _messageStatusNotifiers[messageId]!.value = newStatus;
      });
      DatabaseHelper().updateMessageStatus(messageId, newStatus);
    }
  }

  void handleMessagesRead(
      List<String> messageIds, String readerId, String chatId) {
    if (_chatId == chatId) {
      for (var messageId in messageIds) {
        if (_messageStatusNotifiers.containsKey(messageId)) {
          _updateMessageStatus(messageId, 'READ');
          DataManager()
              .syncManager
              .dbHelper
              .updateMessageStatus(messageId, 'READ');
        }
      }

      // Обновляем статус в _chatStateManager
      final updatedMessages =
          _chatStateManager.messagesNotifier.value.map((message) {
        if (messageIds.contains(message.id)) {
          return message.copyWith(status: 'READ');
        }
        return message;
      }).toList();

      _chatStateManager.messagesNotifier.value = updatedMessages;
      _saveMessagesToCache(updatedMessages);
    }
  }

  void _handleMessageEdited(
      String messageId, String newContent, String editedAt) {
    final messages = _chatStateManager.messagesNotifier.value;
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index != -1) {
      final updatedMessage = messages[index].copyWith(
        content: newContent,
        isEdited: true,
        editedAt: DateTime.parse(editedAt),
      );
      _chatStateManager.messagesNotifier.value = List.from(messages)
        ..[index] = updatedMessage;
      _saveMessagesToCache(_chatStateManager.messagesNotifier.value);
    }
  }

  void _editMessage({
    required String messageId,
    required String chatId,
    required String senderId,
    required String newContent,
  }) async {
    if (_webSocketClientService.stompClient == null) return;

    try {
      _webSocketClientService.editPersonalMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        newContent: newContent,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка редактирования сообщения: $e')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppState().currentChatId = null;
    AppState().isRefresh = true;
    AppState().onMessageReceived = null;
    _lifeCycleListener.dispose();
    _searchController.dispose();
    _typingDotsTimer?.cancel();
    _typingTextNotifier.dispose();
    _chatStateManager.selectedMessages.value = [];
    _chatStateManager.disposeChatState(widget.chatId ?? "");
    super.dispose();
  }

  void _startTimer() {
    _updateUserStatus();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _updateUserStatus();
    });
  }

  Future<void> _saveUserStatus(Map<String, dynamic> status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_status_${widget.recipientId}', json.encode(status));
  }

  Future<Map<String, dynamic>?> _loadUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final statusJson = prefs.getString('user_status_${widget.recipientId}');
    if (statusJson != null) {
      return json.decode(statusJson);
    }
    return null;
  }

  Future<void> _updateUserStatus() async {
    final cachedStatus = await _loadUserStatus();
    if (cachedStatus != null) {
      final isOnline = cachedStatus['status'] == 'online';
      final lastSeen = cachedStatus['lastSeen'];

      if (_chatStateManager.isOnlineNotifier.value != isOnline) {
        _chatStateManager.isOnlineNotifier.value = isOnline;
      }

      if (lastSeen != null) {
        final formattedLastSeen = await formatLastSeen(lastSeen);
        if (_chatStateManager.formattedLastSeenNotifier.value !=
            formattedLastSeen) {
          _chatStateManager.formattedLastSeenNotifier.value = formattedLastSeen;
        }
      }
    }

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        final status = await getUserStatus(widget.recipientId);
        final isOnline = status['status'] == 'online';
        final lastSeen = status['lastSeen'];

        if (_chatStateManager.isOnlineNotifier.value != isOnline) {
          _chatStateManager.isOnlineNotifier.value = isOnline;
        }

        if (lastSeen != null) {
          final formattedLastSeen = await formatLastSeen(lastSeen);
          if (_chatStateManager.formattedLastSeenNotifier.value !=
              formattedLastSeen) {
            _chatStateManager.formattedLastSeenNotifier.value =
                formattedLastSeen;
          }
        }

        await _saveUserStatus(status);
      }
    } on SocketException catch (_) {
      print('Нет доступа к интернету. Статус загружен из кеша.');
    } catch (e) {
      print('Ошибка обновления статуса: $e');
    }
  }

  void _addMessage(Message message) {
    _chatStateManager.messagesNotifier.value = [
      ..._chatStateManager.messagesNotifier.value,
      message,
    ];

    _messageStatusNotifiers[message.id] = ValueNotifier(message.status);

    final dbHelper = DatabaseHelper();
    dbHelper.insertMessage(message);
    scrollToBottom();
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<List<PhotoModel>> fetchPhotos(String chatId) async {
    final hasInternet = await checkInternetConnection();
    if (hasInternet) {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chats/$chatId/photos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => PhotoModel.fromJson(item)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception(
            'Ошибка при получении фотографий для чата: ${response.statusCode}');
      }
    }
    return [];
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw Exception('Пользователь не найден в кэше');
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw Exception('Токен пуст');
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      await TokenManager.refreshToken();

      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw Exception(
            'Пользователь не найден в кэше после обновления токена');
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw Exception('Токен пуст после обновления');
      }

      response = await request();
    }

    return response;
  }

  void removeMessageFromChat(String chatId, String messageId) {
    _chatStateManager.messagesNotifier.value =
        List.from(_chatStateManager.messagesNotifier.value)
          ..removeWhere((message) => message.id == messageId);
  }

  void _sendTypingStatus(bool isTyping) {
    if (_chatId != null) {
      _webSocketClientService.sendTypingStatus(
        chatId: _chatId!,
        initiatorUserId: widget.userId,
        isTyping: isTyping,
      );
    }
  }

  void _sendMessage(String content) async {
    if (_chatId == null) {
      try {
        final response = await _handleRequestWithTokenRefresh(() async {
          final headers = await _getHeaders();
          return await http.post(
            Uri.parse(
                '${Constants.baseUrl}${Constants.createOneToOneChatEndpoint}'),
            headers: headers,
            body: json.encode({
              'firstUserId': widget.userId,
              'secondUserId': widget.recipientId,
            }),
          );
        });

        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (response.statusCode == 200) {
          final chatId = responseData['chatId'];
          final chatCreated = responseData['chatCreated'];

          if (chatCreated == true && chatId != null) {
            setState(() {
              _chatId = chatId;
            });

            final chat = Chat(
                id: chatId,
                user1Id: widget.userId,
                user2Id: widget.recipientId,
                createdAt: DateTime.now().toIso8601String(),
                username: '',
                email: '',
                descriptionOfProfile: '',
                status: '',
                lastMessage: null,
                notRead: 0,
                lastSequence: 0);

            final db = DatabaseHelper();
            await db.insertChat(chat);

            AppState().currentChatId = _chatId;
            AppState().onMessageReceived = (message) {
              if (message.senderId == widget.recipientId ||
                  message.senderId == widget.userId) {
                _addMessage(message);
              }
              _updateUserStatus();
            };
            _webSocketClientService.sendMessage(
              widget.recipientId,
              chatId,
              content,
              messageType: 'TEXT',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка: чат не был создан')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сервера: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } else {
      if (_chatStateManager.replyMessageNotifier.value != null) {
        _webSocketClientService.sendReplyMessage(
          widget.recipientId,
          _chatId!,
          content,
          _chatStateManager.replyMessageNotifier.value!.id,
        );
      } else if (_chatStateManager.forwardMessageNotifier.value != null) {
        _webSocketClientService.sendMessage(
          widget.recipientId,
          _chatId!,
          content,
          messageType: 'TEXT',
          parentMessageId: _chatStateManager.forwardMessageNotifier.value!.id,
        );
      } else {
        _webSocketClientService.sendMessage(
          widget.recipientId,
          _chatId!,
          content,
          messageType: 'TEXT',
        );
      }
      _chatStateManager.replyMessageNotifier.value = null;
      _chatStateManager.forwardMessageNotifier.value = null;
    }
  }

  void _sendPhotoMessage(String photoUrl) async {
    if (_chatId == null) {
      try {
        final response = await _handleRequestWithTokenRefresh(() async {
          final headers = await _getHeaders();
          return await http.post(
            Uri.parse(
                '${Constants.baseUrl}${Constants.createOneToOneChatEndpoint}'),
            headers: headers,
            body: json.encode({
              'firstUserId': widget.userId,
              'secondUserId': widget.recipientId,
            }),
          );
        });

        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (response.statusCode == 200) {
          final chatId = responseData['chatId'];
          final chatCreated = responseData['chatCreated'];

          if (chatCreated == true && chatId != null) {
            setState(() {
              _chatId = chatId;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('chatId_${widget.recipientId}', chatId);
            _sendPhotoMessage(photoUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка: чат не был создан')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сервера: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } else {
      _webSocketClientService.sendPhotoMessage(
        widget.recipientId,
        _chatId!,
        photoUrl,
      );
    }
  }

  void _handleReply(Message message) {
    _chatStateManager.replyMessageNotifier.value = message;
  }

  void _handleForward(Message message) {
    _chatStateManager.forwardMessageNotifier.value = message;
    _openChatSelectionPage(context, message.content);
  }

  Message? _findMessageById(String messageId) {
    for (var i = 0;
        i < _chatStateManager.messagesNotifier.value.length - 1;
        i++) {
      if (_chatStateManager.messagesNotifier.value[i].id == messageId) {
        return _chatStateManager.messagesNotifier.value[i];
      }
    }
    return null;
  }

  void _toggleProfileOverlay() async {
    final userId = await loadUserId();
    if (recipientProfile == null) return;

    List<PhotoModel> mediaUrls = [];
    if (_chatId != null) {
      mediaUrls = await _getMediaUrls(_chatId!);
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenProfileInfo(
          userId: userId,
          profile: recipientProfile!,
          onPickImage: () async {},
          onUpdateEmoji: (emoji) async {},
          onUpdatePremium: (isPremium) async {},
          mediaUrls: mediaUrls,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _onLifeCycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _updateUserStatus();
        if (!_isLoadingMessages) {
          _loadMessagesFromServer();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _deleteSelectedMessages() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение удаления'),
          content: Text('Вы уверены, что хотите удалить выбранные сообщения?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Отмена
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Подтверждение
              },
              child: Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        List<String> selectedMessages =
            List.from(_chatStateManager.selectedMessages.value);
        _webSocketClientService.deleteMessages(_chatId!, selectedMessages);
        _chatStateManager.selectedMessagesNotifier.value.clear();
        _chatStateManager.selectedMessagesNotifier.notifyListeners();
        _saveMessagesToCache(_chatStateManager.messagesNotifier.value);
      } catch (e) {
        print('Error deleting messages: $e');
      }
    }
  }

  void _openChatSelectionPage(
      BuildContext context, String messageContent) async {
    final chats = await _getUserChats(widget.userId);
    final lastMessages = await getLastMessagesForChats(chats);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSelectionPage(
          chats: chats,
          lastMessages: lastMessages,
          messageContent: messageContent,
          userId: widget.userId,
          onSendMessage: (chatId, recipientId, messageContent) {
            _sendForwardedMessage(chatId, recipientId, messageContent);
          },
        ),
      ),
    );
  }

  void _sendForwardedMessage(
      String chatId, String recipientId, String messageContent) {
    _webSocketClientService.sendReplyMessage(
      recipientId,
      chatId,
      messageContent,
      _chatStateManager.forwardMessageNotifier.value!.id,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сообщение успешно переслано')),
    );
  }

  Future<void> _loadMessagesFromCache() async {}

  Future<Map<String, dynamic>> getUserProfileForChat(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(
          '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUserProfileForProfileInfo(
      String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/user/profile/$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (err) {
      print(err);
    }
    return {};
  }

  Future<Map<String, dynamic>> getUserStatus(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/ups/api/users/$userId/status'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 404) {
      throw Exception('Пользователь не найден.');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<void> deleteMessages(List<String> messageIds) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/messages/delete'),
      headers: headers,
      body: json.encode(messageIds),
    );

    if (response.statusCode == 200) {
    } else {
      throw Exception('Ошибка при удалении сообщений: ${response.body}');
    }
  }

  Future<void> _loadMessagesFromServer() async {
    if (_chatId != null) {
      var messages =
          await DataManager().syncManager.dbHelper.getMessages(_chatId!);
      _chatStateManager.messagesNotifier.value = messages;
    }
  }

  Future<void> _saveMessagesToCache(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = messages.map((message) {
      final messageJson = message.toJson();
      messageJson.remove('parentMessage');
      return messageJson;
    }).toList();
    prefs.setString(
        'cached_messages_${widget.chatId}', json.encode(messagesJson));
  }

  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final backgroundImage = prefs.getString('background_image');
    setState(() {
      _backgroundImage = backgroundImage;
    });
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    await DatabaseHelper().insertProfile(profile);
  }

  Future<Map<String, dynamic>?> loadProfile(String userId) async {
    return await DatabaseHelper().getProfile(userId);
  }

  Future<void> _loadProfileInfo() async {
    final profile = await DatabaseHelper().getProfile(widget.recipientId);
    if (profile != null) {
      _chatStateManager.profileNotifier.value = profile;
    }

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        final profileData =
            await getUserProfileForProfileInfo(widget.recipientId);
        _chatStateManager.profileNotifier.value = profileData;

        await DatabaseHelper().insertProfile(profileData);
        isLoading.value = false;
      }
    } on SocketException catch (_) {
      isLoading.value = true;
      print(
          'Нет доступа к интернету. Данные загружены из локальной базы данных.');
    }
  }

  Widget _buildBackgroundImage() {
    if (_backgroundImage != null) {
      return Positioned.fill(
        child: Image.file(
          File(_backgroundImage!),
          fit: BoxFit.cover,
        ),
      );
    }
    return Container();
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
        child: Container(),
      );
    }
    return Container();
  }

  void _handleCall() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            username: _userProfile["username"],
            avatarUrl: _userProfile['avatarUrl'],
            status: CallStatus.connecting,
          ),
        ));
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (_) => IncomingCallPage(
    //         username: _userProfile["username"],
    //         avatarUrl: _userProfile['avatarUrl'],
    //         isVideoCall: false,
    //       ),
    //     ));
  }

  void _handleSearch() {
    setState(() {
      _chatStateManager.isSearchingNotifier.value = true;
    });
  }

  void _clearChat() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение очистки'),
          content: Text('Вы уверены, что хотите очистить весь чат?'),
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
              child: Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final messageIds = _chatStateManager.messagesNotifier.value
            .map((message) => message.id)
            .toList();
        await deleteMessages(messageIds);
        _chatStateManager.messagesNotifier.value = [];
        _saveMessagesToCache(_chatStateManager.messagesNotifier.value);
        AppState().isRefresh = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Чат успешно очищен')),
        );
      } catch (e) {
        print('Ошибка при очистке чата: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось очистить чат: $e')),
        );
      }
    }
  }

  void _searchMessages(String query) {
    if (query.isEmpty) {
      _chatStateManager.searchResultsNotifier.value = [];
      setState(() {
        _chatStateManager.isSearchingNotifier.value = false;
      });
      return;
    }

    final results = _chatStateManager.messagesNotifier.value
        .where((message) =>
            message.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    _chatStateManager.searchResultsNotifier.value = results;

    if (results.isNotEmpty) {
      _scrollToMessage(results.first);
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    return position.pixels < MediaQuery.of(context).size.height;
  }

  void _scrollToMessage(Message message) {
    final index = _chatStateManager.messagesNotifier.value.indexOf(message);
    if (index != -1) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent - (index * 100.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  AppBar _buildAppBar(
    BuildContext context,
    Map<String, dynamic> userProfile,
    bool isSearching,
    AppColors colors,
    bool isPremium,
    String nicknameEmoji,
  ) {
    final bool isLottieEmoji = nicknameEmoji.startsWith('assets/');
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.appBarColor,
      elevation: 0,
      leading: !isSearching
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: colors.iconColor,
              ),
              onPressed: () {
                Navigator.pop(context);
                DataManager().getChats(widget.userId);
              },
            )
          : SizedBox(),
      title: isSearching
          ? TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск сообщений...',
                hintStyle: TextStyle(color: colors.textColor),
                border: InputBorder.none,
              ),
              style: TextStyle(color: colors.textColor),
              onChanged: _searchMessages,
            )
          : GestureDetector(
              onTap: _toggleProfileOverlay,
              child: Row(
                children: [
                  _buildAvatar(
                      colors, userProfile['avatarUrl'], recipientUserName),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isFavoriteChat ? 'Избранное' : recipientUserName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          if (isPremium &&
                              nicknameEmoji.isNotEmpty &&
                              !isFavoriteChat)
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
                                      style: const TextStyle(fontSize: 18),
                                    ),
                            ),
                        ],
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: isLoading,
                        builder: (context, isLoading, _) {
                          return Row(
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    _chatStateManager.isOnlineNotifier,
                                builder: (context, isOnline, _) {
                                  return ValueListenableBuilder<String>(
                                    valueListenable: _chatStateManager
                                        .formattedLastSeenNotifier,
                                    builder: (context, formattedLastSeen, _) {
                                      return ValueListenableBuilder<
                                          Map<String, Map<String, bool>>>(
                                        valueListenable:
                                            AppState().typingStatusNotifier,
                                        builder: (context, typingStatus, _) {
                                          final isTyping =
                                              typingStatus[widget.chatId ?? ""]
                                                      ?[widget.recipientId] ??
                                                  false;
                                          return ValueListenableBuilder<
                                              Map<String, Map<String, bool>>>(
                                            valueListenable:
                                                AppState().typingStatusNotifier,
                                            builder:
                                                (context, typingStatus, _) {
                                              final isTyping = typingStatus[
                                                          widget.chatId ?? ""]
                                                      ?[widget.recipientId] ??
                                                  true;
                                              return AnimatedSwitcher(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                child: isFavoriteChat
                                                    ? SizedBox()
                                                    : !isTyping
                                                        ? TypingIndicator(
                                                            isTyping: isTyping)
                                                        : Text(
                                                            isOnline
                                                                ? 'онлайн'
                                                                : 'был(а) в сети $formattedLastSeen',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isOnline
                                                                  ? colors
                                                                      .successColor
                                                                  : colors
                                                                      .hintColor,
                                                            ),
                                                          ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              if (isLoading)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
      actions: [
        if (isSearching)
          IconButton(
            icon: Icon(
              Icons.close,
              color: colors.iconColor,
            ),
            onPressed: _clearSearch,
          )
        else
          PopupMenuButton<String>(
            color: colors.backgroundColor,
            icon: Icon(
              Icons.more_vert,
              color: colors.iconColor,
            ),
            onSelected: (String value) {
              if (value == 'call') {
                // _handleCall();
              } else if (value == 'search') {
                _handleSearch();
              } else if (value == 'clear_chat') {
                _clearChat();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // PopupMenuItem<String>(
              //   value: 'call',
              //   child: ListTile(
              //     leading: Icon(
              //       Icons.phone,
              //       color: colors.iconColor,
              //     ),
              //     title: Text(
              //       'Звонок',
              //       style: TextStyle(
              //         color: colors.textColor,
              //       ),
              //     ),
              //   ),
              // ),
              PopupMenuItem<String>(
                value: 'search',
                child: ListTile(
                  leading: Icon(
                    Icons.search,
                    color: colors.iconColor,
                  ),
                  title: Text(
                    'Поиск сообщений',
                    style: TextStyle(
                      color: colors.textColor,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear_chat',
                child: ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: colors.iconColor,
                  ),
                  title: Text(
                    'Очистить чат',
                    style: TextStyle(
                      color: colors.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ValueListenableBuilder<List<String>>(
          valueListenable: ChatStateManager.instance.selectedMessages,
          builder: (context, selectedMessages, _) {
            final count = selectedMessages.length;
            if (count > 0) {
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.shadowColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        ValueListenableBuilder<List<String>>(
          valueListenable: _chatStateManager.selectedMessages,
          builder: (context, selectedMessages, _) {
            if (selectedMessages.isNotEmpty) {
              return IconButton(
                icon: Icon(
                  Icons.delete,
                  color: colors.iconColor,
                ),
                onPressed: _deleteSelectedMessages,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(AppColors colors, String? avatarUrl, String username) {
    if (isFavoriteChat) {
      return Hero(
        tag: username,
        child: CircleAvatar(
          backgroundColor: colors.backgroundColor,
          radius: 24,
          child: Icon(
            Icons.star,
            color: colors.primaryColor,
            size: 30,
          ),
        ),
      );
    }

    return avatarUrl == null
        ? CircleAvatar(
            backgroundColor: colors.backgroundColor,
            radius: 24,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
              ),
            ),
          )
        : CachedNetworkImage(
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
          );
  }

  bool get isFavoriteChat {
    return widget.userId != null && widget.recipientId == widget.userId;
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateScrollButtonVisibility() {
    setState(() {
      _showScrollButton = !_isAtBottom();
    });
  }

  Widget _buildMessageList(List<Message> messages, AppColors colors) {
    for (var message in messages) {
      if (!messageKeys.containsKey(message.id)) {
        messageKeys[message.id] = GlobalKey();
      }
    }

    final allMyMessagesRead = true;

    if (allMyMessagesRead) {
      messages = messages.reversed.toList();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: allMyMessagesRead,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final nextMessage =
            index < messages.length - 1 ? messages[index + 1] : null;

        Duration timeDifference = nextMessage != null
            ? nextMessage.timestamp.difference(message.timestamp)
            : Duration.zero;

        double verticalSpacing = 3.0;
        if (timeDifference.inMinutes <= 5) {
          verticalSpacing = 0.0;
        } else if (timeDifference.inMinutes > 5 &&
            timeDifference.inMinutes <= 10) {
          verticalSpacing = 3.0;
        } else if (timeDifference.inMinutes > 10) {
          verticalSpacing = 5.0;
        }

        bool showDate = nextMessage == null ||
            message.timestamp.year != nextMessage.timestamp.year ||
            message.timestamp.month != nextMessage.timestamp.month ||
            message.timestamp.day != nextMessage.timestamp.day;

        return Column(
          key: messageKeys[message.id],
          children: [
            if (showDate)
              IntrinsicWidth(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 12.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    formatDate(message.timestamp),
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(bottom: verticalSpacing),
              child: MessageBubble(
                key: ValueKey(message.id),
                message: message,
                userId: widget.userId,
                isRead: false,
                parentMessage: _findMessageById(message.parentMessageId ?? ""),
                onReply: () => _handleReply(message),
                onSendMessage: () => _handleForward(message),
                onEditMessage: () {
                  _chatStateManager.editingMessageNotifier.value = message;
                },
                onRepeat: () {
                  DataManager().syncManager.dbHelper.deleteMessage(message.id);
                  _sendMessage(message.content);

                  _chatStateManager.messagesNotifier.value = _chatStateManager
                      .messagesNotifier.value
                      .where((msg) => msg.id != message.id)
                      .toList();
                },
                onReading: () {
                  if (message.senderId != widget.userId) {
                    _markMessagesAsRead([message.id], widget.chatId ?? "");
                    DataManager()
                        .syncManager
                        .dbHelper
                        .updateMessageStatus(message.id, "READ");
                  }
                },
                onTapReply: () async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return;

                  final GlobalKey? messageKey =
                      messageKeys[message.parentMessageId];

                  Future<void> scrollToMessage(
                      ScrollController scrollController) async {
                    int attempts = 0;
                    const maxAttempts = 20;
                    const delayBetweenAttempts = Duration(milliseconds: 100);
                    final double screenHeight =
                        MediaQuery.of(context).size.height;
                    final double scrollStep = screenHeight * 3;

                    while (scrollController.position.pixels <
                        scrollController.position.maxScrollExtent) {
                      if (messageKey?.currentContext != null) {
                        Scrollable.ensureVisible(
                          messageKey!.currentContext!,
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOut,
                          alignment: 0.5,
                        );
                        break;
                      } else {
                        if (scrollController.hasClients &&
                            scrollController.position.pixels <
                                scrollController.position.maxScrollExtent) {
                          scrollController.animateTo(
                            scrollController.position.pixels + scrollStep,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          print(
                              "Достигнута нижняя граница списка или ScrollController не привязан.");
                          break;
                        }
                      }

                      await Future.delayed(delayBetweenAttempts);
                      attempts++;
                    }

                    if (attempts == maxAttempts) {
                      print(
                          "Не удалось найти контекст после $maxAttempts попыток.");
                    }
                  }

                  if (messageKey?.currentContext != null) {
                    Scrollable.ensureVisible(
                      messageKey!.currentContext!,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      alignment: 0.5,
                    );
                    _chatStateManager.isSelectedDelay.value =
                        message.parentMessageId!;
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted) {
                        ChatStateManager.instance.isSelectedDelay.value = "";
                      }
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        await scrollToMessage(_scrollController);
                      }
                    });
                  }
                },
                messageStatusNotifier: _messageStatusNotifiers[message.id] ??
                    ValueNotifier<String>(message.id),
              ),
            ),
          ],
        );
      },
    );
  }

  void _markMessagesAsRead(List<String> messageIds, String chatId) async {
    if (_webSocketClientService.stompClient == null) return;

    try {
      await _webSocketClientService.markMessagesAsRead(
        chatId: chatId,
        messageIds: messageIds,
      );
    } catch (e) {
      print('Ошибка отправки события прочтения сообщений: $e');
    }
  }

  Widget _buildProfileOverlay(AppColors colors) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleProfileOverlay,
        child: Container(
          color: colors.overlayColor,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colors.iconColor,
                        ),
                        onPressed: _toggleProfileOverlay,
                      ),
                    ],
                  ),
                  if (recipientProfile != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: ProfileInfo(
                          profile: recipientProfile!,
                          onPickImage: () async {},
                          onUpdateEmoji: (emoji) async {},
                          onUpdatePremium: (isPremium) async {},
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  final Map<String, GlobalKey> messageKeys = {};

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    _loadMessagesFromServer();

    return SwipeBackWrapper(
      child: ValueListenableBuilder<SharedPreferences>(
        valueListenable: SharedPreferencesSingleton.getInstance(),
        builder: (context, sharedPreferences, _) {
          if (sharedPreferences == null) {
            return Center(
              child: Text(
                'Ошибка загрузки настроек',
                style: TextStyle(color: colors.textColor),
              ),
            );
          } else {
            return BlocProvider(
              create: (context) => ChatBloc(
                fetchMessagesUseCase: FetchMessagesUseCase(
                  ChatRepositoryImpl(
                    localDataSource: ChatLocalDataSourceImpl(
                      sharedPreferences: sharedPreferences,
                    ),
                    remoteDataSource: ChatRemoteDataSourceImpl(
                      client: http.Client(),
                      webSocketClientService: _webSocketClientService,
                    ),
                  ),
                ),
                sendMessageUseCase: SendMessageUseCase(
                  ChatRepositoryImpl(
                    localDataSource: ChatLocalDataSourceImpl(
                      sharedPreferences: sharedPreferences,
                    ),
                    remoteDataSource: ChatRemoteDataSourceImpl(
                      client: http.Client(),
                      webSocketClientService: _webSocketClientService,
                    ),
                  ),
                ),
                webSocketClientService: _webSocketClientService,
              )..add(
                  _chatId != null
                      ? FetchMessagesEvent(
                          FetchMessagesParams(chatId: _chatId!))
                      : FetchMessagesEvent(FetchMessagesParams(chatId: '')),
                ),
              child: BlocListener<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatSuccess) {
                    _chatStateManager.messagesNotifier.value = state.messages;
                    _initializeMessageStatusNotifiers(state.messages);

                    _saveMessagesToCache(state.messages);
                  } else if (state is NewMessageReceived) {}
                },
                child: ValueListenableBuilder<Map<String, dynamic>>(
                  valueListenable: _chatStateManager.profileNotifier,
                  builder: (context, profileSnapshot, _) {
                    if (profileSnapshot.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colors.primaryColor,
                        ),
                      );
                    } else if (profileSnapshot.containsKey('error')) {
                      return Center(
                        child: Text(
                          'Ошибка загрузки профиля',
                          style: TextStyle(color: colors.textColor),
                        ),
                      );
                    } else {
                      _userProfile = profileSnapshot;
                      recipientUserName = _userProfile['username'];
                      final nicknameEmoji = _userProfile['nicknameEmoji'] ?? '';
                      final isPremium = _userProfile['premium'] ?? false;
                      recipientProfile = Profile.fromJson(_userProfile);

                      return GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (details.primaryDelta! > 10) {
                            Navigator.pop(context);
                            DataManager().getChats(widget.userId);
                          }
                        },
                        child: Scaffold(
                          backgroundColor: colors.backgroundColor,
                          appBar: _buildAppBar(
                              context,
                              _userProfile,
                              _chatStateManager.isSearchingNotifier.value,
                              colors,
                              isPremium,
                              nicknameEmoji),
                          body: Stack(
                            children: [
                              _buildBackgroundImage(),
                              Column(
                                children: [
                                  Expanded(
                                    child: NotificationListener<
                                        ScrollNotification>(
                                      onNotification: (scrollNotification) {
                                        if (scrollNotification
                                            is ScrollEndNotification) {
                                          _updateScrollButtonVisibility();
                                        }
                                        return true;
                                      },
                                      child:
                                          ValueListenableBuilder<List<Message>>(
                                        valueListenable: _chatStateManager
                                                .isSearchingNotifier.value
                                            ? _chatStateManager
                                                .searchResultsNotifier
                                            : _chatStateManager
                                                .messagesNotifier,
                                        builder: (context, messages, _) {
                                          return _buildMessageList(
                                              messages, colors);
                                        },
                                      ),
                                    ),
                                  ),
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 300),
                                    crossFadeState: _chatStateManager
                                            .showMessageInputNotifier.value
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    firstChild: MessageInput(
                                      chatId: _chatId,
                                      userId: widget.userId,
                                      recipientId: widget.recipientId,
                                      onSend: _sendMessage,
                                      onSendPhoto: _sendPhotoMessage,
                                      typing: _sendTypingStatus,
                                      replyMessageNotifier: _chatStateManager
                                          .replyMessageNotifier,
                                      onEditMessage: _editMessage,
                                    ),
                                    secondChild: const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              if (_showScrollButton)
                                Positioned(
                                  bottom: 80,
                                  right: 16,
                                  child: FloatingActionButton(
                                    backgroundColor: colors.appBarColor,
                                    shape: CircleBorder(),
                                    onPressed: _scrollToBottom,
                                    child: Icon(
                                      Icons.arrow_downward,
                                      color: colors.iconColor,
                                    ),
                                  ),
                                ),
                              if (isProfileOverlayVisible)
                                _buildProfileOverlay(colors),
                              IgnorePointer(
                                child: _buildSnowfall(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _clearSearch() {
    setState(() {
      _chatStateManager.isSearchingNotifier.value = false;
      _chatStateManager.showMessageInputNotifier.value = true;
      _searchController.clear();
      _chatStateManager.searchResultsNotifier.value = [];
    });
  }

  Future<List<PhotoModel>> _getMediaUrls(String chatId) async {
    final photos = await fetchPhotos(chatId);
    return photos;
  }
}

Future<String> formatLastSeen(String? lastSeen) async {
  if (lastSeen == null) {
    return 'Недавно';
  }
  final DateTime now = DateTime.now();
  final DateTime lastSeenDateTime = DateTime.parse(lastSeen);

  final String localTimeZone = await FlutterTimezone.getLocalTimezone();
  final int offsetInHours = DateTime.now().timeZoneOffset.inHours;

  final DateTime adjustedLastSeenDateTime =
      lastSeenDateTime.add(Duration(hours: offsetInHours));

  if (adjustedLastSeenDateTime.year == now.year &&
      adjustedLastSeenDateTime.month == now.month &&
      adjustedLastSeenDateTime.day == now.day) {
    return '${adjustedLastSeenDateTime.hour.toString().padLeft(2, '0')}:${adjustedLastSeenDateTime.minute.toString().padLeft(2, '0')}';
  } else if (adjustedLastSeenDateTime.year == now.year &&
      adjustedLastSeenDateTime.month == now.month &&
      adjustedLastSeenDateTime.day == now.day - 1) {
    return 'Вчера в ${adjustedLastSeenDateTime.hour.toString().padLeft(2, '0')}:${adjustedLastSeenDateTime.minute.toString().padLeft(2, '0')}';
  } else {
    return '${adjustedLastSeenDateTime.day.toString().padLeft(2, '0')}.${adjustedLastSeenDateTime.month.toString().padLeft(2, '0')} ${adjustedLastSeenDateTime.hour.toString().padLeft(2, '0')}:${adjustedLastSeenDateTime.minute.toString().padLeft(2, '0')}';
  }
}

String formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return 'Сегодня';
  } else if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'Вчера';
  } else {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}

Future<List<Map<String, dynamic>>> getLastMessagesForChats(
    List<Chat> chats) async {
  final headers = await _getHeaders();
  final List<Map<String, dynamic>> lastMessages = [];

  for (final chat in chats) {
    final response = await http.get(
      Uri.parse(
          '${Constants.baseUrl}/messages/getAllMessagesInChat?chatId=${chat.id}'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final messages =
          json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      if (messages.isNotEmpty) {
        lastMessages.add(messages.last);
      } else {
        lastMessages.add({});
      }
    } else {
      lastMessages.add({});
    }
  }

  return lastMessages;
}

Future<List<Chat>> _getUserChats(String userId) async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('${Constants.baseUrl}/chats/allChats?userId=$userId'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((item) => Chat.fromJson(item)).toList();
  } else {
    throw Exception('Ошибка при получении чатов: ${response.statusCode}');
  }
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
