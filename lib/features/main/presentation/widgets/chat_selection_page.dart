import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../chat/presentation/widgets/custom_message_input.dart';
import '../../data/models/chat_model.dart';
import '../../domain/entities/chat.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class ChatSelectionPage extends StatefulWidget {
  final List<Chat> chats;
  final List<Map<String, dynamic>> lastMessages;
  final String messageContent;
  final String userId;
  final Function(String, String, String) onSendMessage;

  const ChatSelectionPage({
    required this.chats,
    required this.lastMessages,
    required this.messageContent,
    required this.userId,
    required this.onSendMessage,
    super.key,
  });

  @override
  _ChatSelectionPageState createState() => _ChatSelectionPageState();
}

class _ChatSelectionPageState extends State<ChatSelectionPage> {
  final TextEditingController _controller = TextEditingController();
  String _userMessage = '';

  Future<Map<String, dynamic>> getUserProfileForChat(String userId) async {
    final response = await _handleRequestWithTokenRefresh(() async {
      final headers = await _getHeaders();
      return await http.get(
        Uri.parse(
            '${Constants.baseUrl}${Constants.getUserProfileForChatEndpoint}$userId'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
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
      throw Exception('Токен недоступен');
    }
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw Exception('Кэш пользователя недоступен');
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw Exception('Токен недоступен');
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      // Обновление токена
      await TokenManager.refreshToken();

      // Повторный запрос с обновленным токеном
      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw Exception('Кэш пользователя недоступен');
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw Exception('Токен недоступен');
      }

      response = await request();
    }

    return response;
  }

  bool _isImageUrl(String url) {
    return url.endsWith('.jpg') ||
        url.endsWith('.png') ||
        url.endsWith('.jpeg');
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

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Выберите чат',
          style: TextStyle(color: colors.textColor),
        ),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.chats.length,
              itemBuilder: (context, index) {
                final chat = widget.chats[index];
                final lastMessage = widget.lastMessages[index];
                final recipientId = (chat.user2Id == widget.userId)
                    ? chat.user1Id
                    : chat.user2Id;

                return FutureBuilder<Map<String, dynamic>>(
                  future: getUserProfileForChat(recipientId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: CircularProgressIndicator(
                          color: colors.primaryColor,
                        ),
                        title: Text(
                          'Загрузка...',
                          style: TextStyle(color: colors.textColor),
                        ),
                        subtitle: RichText(
                          text: TextSpan(
                            children: _formatMessageContent(
                              lastMessage['content'] ?? 'Нет сообщений',
                              widget.userId,
                              lastMessage['senderId'],
                            ),
                            style: TextStyle(color: colors.textColor),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text(
                          'Ошибка: ${snapshot.error}',
                          style: TextStyle(color: colors.textColor),
                        ),
                        subtitle: RichText(
                          text: TextSpan(
                            children: _formatMessageContent(
                              lastMessage['content'] ?? 'Нет сообщений',
                              widget.userId,
                              lastMessage['senderId'],
                            ),
                            style: TextStyle(color: colors.textColor),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final profileData = snapshot.data!;
                      final username = profileData['username'] ?? '';
                      final avatarUrl = profileData['avatarUrl'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          backgroundColor: colors.backgroundColor,
                          radius: 24,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : '',
                                  style: TextStyle(
                                    color: colors.textColor,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          username,
                          style: TextStyle(color: colors.textColor),
                        ),
                        subtitle: lastMessage['content'] != null &&
                                _isImageUrl(lastMessage['content'])
                            ? Text(
                                'Фотография',
                                style: TextStyle(
                                  color: Colors.lightBlue,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : lastMessage['content'] != null &&
                                    lastMessage['content']
                                        .startsWith('::animation_emoji/')
                                ? Text(
                                    _getReplacementEmoji(
                                      lastMessage['content'].replaceFirst(
                                          '::animation_emoji/', ''),
                                    ),
                                    style: TextStyle(
                                        fontSize: 24, color: colors.textColor),
                                  )
                                : RichText(
                                    text: TextSpan(
                                      children: _formatMessageContent(
                                        lastMessage['content'] ??
                                            'Нет сообщений',
                                        widget.userId,
                                        lastMessage['senderId'],
                                      ),
                                      style: TextStyle(color: colors.textColor),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        onTap: () {
                          widget.onSendMessage(
                              chat.id, recipientId, _userMessage);
                          Navigator.pop(context);
                        },
                      );
                    } else {
                      return ListTile(
                        title: Text(
                          'Нет данных',
                          style: TextStyle(color: colors.textColor),
                        ),
                        subtitle: RichText(
                          text: TextSpan(
                            children: _formatMessageContent(
                              lastMessage['content'] ?? 'Нет сообщений',
                              widget.userId,
                              lastMessage['senderId'],
                            ),
                            style: TextStyle(color: colors.textColor),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          CustomMessageInput(
            controller: _controller,
            onTextChanged: (text) {
              setState(() {
                _userMessage = text;
              });
            },
          ),
        ],
      ),
    );
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
