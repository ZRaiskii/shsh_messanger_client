import 'package:flutter/material.dart';
import '../../../../core/utils/AppColors.dart';

import '../../../settings/data/services/theme_manager.dart'; // Импортируем AppColors

class CustomMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onTextChanged;

  const CustomMessageInput({
    required this.controller,
    required this.onTextChanged,
    super.key,
  });

  @override
  _CustomMessageInputState createState() => _CustomMessageInputState();
}

class _CustomMessageInputState extends State<CustomMessageInput> {
  final List<String> emojis = [
    '😊',
    '😂',
    '❤️',
    '👍',
    '😢',
    '😱',
    '😴',
    '😠',
    '😈',
    '😇',
    '😋',
    '😌',
    '😘',
    '😜',
    '😝',
    '😞',
    '😒',
    '😓',
    '😔',
    '😕'
  ];

  void _showEmojiPicker() {
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: colors.backgroundColor, // Применяем цвет фона
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  widget.controller.text += emojis[index];
                  widget.onTextChanged(widget.controller.text);
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(
                    emojis[index],
                    style: TextStyle(
                        fontSize: 24,
                        color: colors.textColor), // Применяем цвет текста
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    return Container(
      color: colors.backgroundColor, // Применяем цвет фона
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.emoji_emotions,
                color: colors.iconColor, // Применяем цвет иконки
              ),
              onPressed: _showEmojiPicker,
            ),
            Expanded(
              child: TextField(
                style:
                    TextStyle(color: colors.textColor), // Применяем цвет текста
                controller: widget.controller,
                maxLines: null,
                onChanged: (text) {
                  if (text.length > 2000) {
                    widget.controller.text = text.substring(0, 2000);
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: widget.controller.text.length),
                    );
                  }
                  widget.onTextChanged(text);
                },
                decoration: InputDecoration(
                  hintText: 'Сообщение',
                  hintStyle: TextStyle(
                      color: colors.hintColor), // Применяем цвет подсказки
                  filled: true,
                  fillColor: colors
                      .cardColor, // Применяем цвет фона текстового поля (используем cardColor)
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
