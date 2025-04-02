import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';

class ChatPreview extends StatelessWidget {
  final double messageTextSize;
  final double messageCornerRadius; // Добавляем параметр для радиуса углов
  final AppColors colors;

  const ChatPreview({
    super.key,
    required this.messageTextSize,
    required this.messageCornerRadius, // Принимаем радиус углов
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMessageBubble(
          text: 'Доброе утро! 👋',
          isSentByUser: false,
          messageTextSize: messageTextSize,
          messageCornerRadius: messageCornerRadius, // Передаем радиус углов
          colors: colors,
        ),
        const SizedBox(height: 8),
        _buildMessageBubble(
          text: 'Знаешь, который час?',
          isSentByUser: false,
          messageTextSize: messageTextSize,
          messageCornerRadius: messageCornerRadius, // Передаем радиус углов
          colors: colors,
        ),
        const SizedBox(height: 8),
        _buildMessageBubble(
          text: 'ЩЩутро🌅',
          isSentByUser: true,
          messageTextSize: messageTextSize,
          messageCornerRadius: messageCornerRadius, // Передаем радиус углов
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isSentByUser,
    required double messageTextSize,
    required double messageCornerRadius, // Принимаем радиус углов
    Color? backgroundColor,
    Color? textColor,
    required AppColors colors,
  }) {
    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isSentByUser ? Colors.blue : Colors.grey[300]),
          borderRadius: BorderRadius.circular(
              messageCornerRadius), // Используем радиус углов
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: messageTextSize,
            color: textColor ?? Colors.black,
          ),
        ),
      ),
    );
  }
}
