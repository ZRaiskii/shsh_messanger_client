import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/message.dart';

class ParentMessageWidget extends StatefulWidget {
  final Message parentMessage;
  final String senderName;
  final VoidCallback? onTapReply;

  ParentMessageWidget({
    required this.parentMessage,
    required this.senderName,
    required this.onTapReply,
  });

  @override
  _ParentMessageWidgetState createState() => _ParentMessageWidgetState();
}

class _ParentMessageWidgetState extends State<ParentMessageWidget> {
  Size? _imageSize;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isTextMessage = false;
  bool _isLottieMessage = false;

  @override
  void initState() {
    super.initState();
    _checkMessageType();
    _isTextMessage = !_isImageUrl(widget.parentMessage.content);
    if (!_isTextMessage) {
      _getImageDimensions(widget.parentMessage.content);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkMessageType() {
    if (widget.parentMessage.content.startsWith('::animation_emoji/')) {
      _isLottieMessage = true;
      setState(() => _isLoading = false);
    } else {
      _isTextMessage = !_isImageUrl(widget.parentMessage.content);
      if (!_isTextMessage) {
        _getImageDimensions(widget.parentMessage.content);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Size> _getImageDimensions(String imageUrl) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(imageUrl);

    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        setState(() {
          _imageSize =
              Size(info.image.width.toDouble(), info.image.height.toDouble());
          _isLoading = false;
        });
        completer.complete(_imageSize);
      }),
    );

    return completer.future;
  }

  bool _isImageUrl(String url) {
    return url.startsWith('http') &&
        (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png'));
  }

  @override
  Widget build(BuildContext context) {
    const double fixedPortraitWidth = 40.0;
    const double fixedPortraitHeight = 50.0;
    const double fixedLandscapeWidth = 50.0;
    const double fixedLandscapeHeight = 40.0;

    if (_isLoading) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[300],
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_hasError) {
      return Icon(Icons.error);
    } else if (_isLottieMessage) {
      final emojiPath = widget.parentMessage.content
          .replaceFirst('::animation_emoji/', '')
          .replaceAll('::', '');

      final lottieWidget = Lottie.asset(
        emojiPath,
        width: 25,
        height: 25,
        fit: BoxFit.cover,
        onLoaded: (_) => setState(() => _isLoading = false),
      );

      return widget.onTapReply != null
          ? GestureDetector(
              onTap: widget.onTapReply,
              child: _buildMessageContainer(lottieWidget))
          : _buildMessageContainer(lottieWidget);
    } else if (!_isTextMessage && _imageSize != null) {
      final bool isPortrait = _imageSize!.height > _imageSize!.width;

      return widget.onTapReply != null
          ? GestureDetector(
              onTap: widget.onTapReply,
              child: Container(
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
                      widget.senderName,
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
                        if (isPortrait)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: CachedNetworkImage(
                              imageUrl: widget.parentMessage.content,
                              fit: BoxFit.cover,
                              width: fixedPortraitWidth,
                              height: fixedPortraitHeight,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: CachedNetworkImage(
                              imageUrl: widget.parentMessage.content,
                              fit: BoxFit.cover,
                              width: fixedLandscapeWidth,
                              height: fixedLandscapeHeight,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Container(
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
                    widget.senderName,
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
                      if (isPortrait)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: CachedNetworkImage(
                            imageUrl: widget.parentMessage.content,
                            fit: BoxFit.cover,
                            width: fixedPortraitWidth,
                            height: fixedPortraitHeight,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: CachedNetworkImage(
                            imageUrl: widget.parentMessage.content,
                            fit: BoxFit.cover,
                            width: fixedLandscapeWidth,
                            height: fixedLandscapeHeight,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
    } else {
      return widget.onTapReply != null
          ? GestureDetector(
              onTap: widget.onTapReply,
              child: Container(
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
                      widget.senderName,
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
                        Flexible(
                          child: Text(
                            widget.parentMessage.content,
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
              ),
            )
          : Container(
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
                    widget.senderName,
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
                      Flexible(
                        child: Text(
                          widget.parentMessage.content,
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
    }
  }

  Widget _buildMessageContainer(Widget content) {
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
            widget.senderName,
            style: const TextStyle(
              fontSize: 10.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2.0),
          Row(
            children: [
              Container(
                width: 3.0,
                height: 30.0,
                color: Colors.grey,
              ),
              const SizedBox(width: 6.0),
              content,
            ],
          ),
        ],
      ),
    );
  }
}

Future<String> getUserName(String userId) async {
  final cachedSenderName = await _getCachedSenderName(userId);
  if (cachedSenderName != null) {
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
      await _cacheSenderName(userId, senderName);
      return senderName;
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Ошибка при получении имени пользователя: $e');
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

Future<void> _cacheSenderName(String senderId, String senderName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cached_sender_name_$senderId', senderName);
}

Future<String?> _getCachedSenderName(String senderId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cached_sender_name_$senderId');
}
