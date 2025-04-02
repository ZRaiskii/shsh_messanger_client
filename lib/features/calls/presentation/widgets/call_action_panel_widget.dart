import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class CallActionPanel extends StatelessWidget {
  final List<Widget> actions;

  const CallActionPanel({
    required this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions,
      ),
    );
  }
}
