import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';

class ChangeWallpaperButton extends StatelessWidget {
  final VoidCallback onTap;
  final AppColors colors; // Принимаем AppColors

  const ChangeWallpaperButton({
    required this.onTap,
    required this.colors, // Добавляем AppColors в конструктор
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(
              Icons.photo,
              color: colors.appBarColor, // Используем цвет из AppColors
              size: 24.0,
            ),
            const SizedBox(width: 8),
            Text(
              'Изменить обои',
              style: TextStyle(
                color: colors.appBarColor, // Используем цвет из AppColors
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
