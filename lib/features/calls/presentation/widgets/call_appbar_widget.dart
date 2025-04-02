import 'package:flutter/material.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class CallAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const CallAppBar({
    required this.title,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.iconColor),
        onPressed: onBack,
      ),
      title: Text(title, style: TextStyle(color: colors.textColor)),
      backgroundColor: colors.appBarColor,
      actions: [
        PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: Text('Настройки звука'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
