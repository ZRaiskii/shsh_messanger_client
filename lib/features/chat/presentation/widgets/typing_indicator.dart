import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class TypingIndicator extends StatefulWidget {
  final bool isTyping;
  final Color textColor; // Цвет текста
  final double fontSize; // Размер текста
  final FontStyle fontStyle; // Стиль шрифта

  const TypingIndicator({
    required this.isTyping,
    this.textColor = Colors.grey, // Цвет по умолчанию
    this.fontSize = 12, // Размер текста по умолчанию
    this.fontStyle = FontStyle.italic, // Курсив по умолчанию
    Key? key,
  }) : super(key: key);

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();

    // Инициализация анимации
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Анимация для количества точек
    _dotAnimation = IntTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Text(
          'Печатает${'.' * _dotAnimation.value}',
          style: TextStyle(
            fontSize: widget.fontSize, // Используем переданный размер текста
            color: colors.primaryColor, // Используем переданный цвет текста
            fontStyle: FontStyle.italic, // Используем переданный стиль шрифта
          ),
        );
      },
    );
  }
}
