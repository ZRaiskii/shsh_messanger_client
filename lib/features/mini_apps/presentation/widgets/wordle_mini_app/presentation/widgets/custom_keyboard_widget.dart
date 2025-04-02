import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../core/utils/AppColors.dart';
import '../../../../../../settings/data/services/theme_manager.dart';

class CustomKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final Map<String, Color> letterStatus;

  const CustomKeyboard({
    Key? key,
    required this.onKeyPressed,
    required this.letterStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    final focusNode = FocusNode();

    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (RawKeyEvent event) {
        if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
          Navigator.of(context).pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          var temp = 7;
          if (Platform.isWindows) {
            temp = 25;
          }
          final buttonSize = constraints.maxWidth / temp - 6;
          final specialButtonSize = buttonSize * 2;

          return Focus(
            autofocus: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow('ЙЦУКЕНГШЩЗХЪ', buttonSize, colors),
                _buildRow('ФЫВАПРОЛДЖЭ', buttonSize, colors),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...(_buildRow('ЯЧСМИТЬБЮ', buttonSize, colors) as Row)
                        .children!,
                    _buildSpecialKey(
                      icon: Icons.backspace,
                      size: buttonSize + 20,
                      onPressed: () => onKeyPressed('Backspace'),
                      colors: colors,
                    ),
                  ],
                ),
                _buildSpecialKey(
                  icon: Icons.arrow_forward,
                  size: specialButtonSize,
                  onPressed: () => onKeyPressed('Enter'),
                  colors: colors,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Строит строку кнопок из переданных букв
  Widget _buildRow(String letters, double buttonSize, AppColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: letters.split('').map((letter) {
        return _buildKey(letter, buttonSize, colors);
      }).toList(),
    );
  }

  /// Строит отдельную кнопку для буквы
  Widget _buildKey(String letter, double buttonSize, AppColors colors) {
    final buttonColor = letterStatus[letter] ?? colors.buttonColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ElevatedButton(
          onPressed: () => onKeyPressed(letter),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(buttonSize, buttonSize),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            backgroundColor: buttonColor,
            elevation: 1,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: buttonSize * 0.5,
                fontWeight: FontWeight.bold,
                color: colors.buttonTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Строит специальную кнопку (например, Enter или Backspace)
  Widget _buildSpecialKey({
    IconData? icon,
    required double size,
    required VoidCallback onPressed,
    required AppColors colors,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(size, size / 2),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        backgroundColor: colors.specialButtonColor,
        elevation: 1,
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.5,
          color: colors.buttonTextColor,
        ),
      ),
    );
  }
}
