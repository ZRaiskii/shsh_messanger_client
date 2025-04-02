import 'package:flutter/material.dart';
import '../../../../../../settings/data/services/theme_manager.dart';

import 'AppColors.dart';

class NumberDisplay extends StatelessWidget {
  final int? number;

  const NumberDisplay({super.key, this.number});

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: child,
      ),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: Center(
        key: ValueKey(number),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            number != null ? '$number' : 'Нажмите кнопку',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
