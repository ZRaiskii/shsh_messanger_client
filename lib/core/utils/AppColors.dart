import 'package:flutter/material.dart';

class AppColors {
  final Color backgroundColor; // Основной цвет фона
  final Color textColor; // Основной цвет текста
  final Color appBarColor; // Цвет AppBar
  final Color iconColor; // Цвет иконок
  final Color cardColor; // Цвет карточек
  final Color dividerColor; // Цвет разделителей
  final Color primaryColor; // Основной акцентный цвет
  final Color secondaryColor; // Вторичный акцентный цвет
  final Color buttonColor; // Цвет кнопок
  final Color buttonTextColor; // Цвет текста на кнопках
  final Color errorColor; // Цвет для ошибок
  final Color successColor; // Цвет для успешных действий
  final Color hintColor; // Цвет подсказок (например, в TextField)
  final Color disabledColor; // Цвет для отключённых элементов
  final Color shadowColor; // Цвет теней
  final Color overlayColor; // Цвет для оверлеев (например, модальных окон)
  final Color accentColor; // Дополнительный акцентный цвет
  final Color callBackgroundColor;
  final Color borderColor; // Цвет границ
  final Color specialButtonColor; // Новый цвет для специальных кнопок
  final Color disabledCardColor;
  final Color shimmerBase; // Базовый цвет для скелетон-лоадера
  final Color shimmerHighlight; // Цвет подсветки для скелетон-лоадера
  final Color inputBackground; // Цвет фона для текстовых полей
  final Color listItemBackground; // Цвет фона для элементов списка
  final Color surface; // Цвет поверхности (например, для карточек)
  final Color progressBackground; // Цвет фона прогресс-бара

  AppColors({
    required this.backgroundColor,
    required this.textColor,
    required this.appBarColor,
    required this.iconColor,
    required this.cardColor,
    required this.dividerColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.errorColor,
    required this.successColor,
    required this.hintColor,
    required this.disabledColor,
    required this.shadowColor,
    required this.overlayColor,
    required this.accentColor,
    required this.callBackgroundColor,
    required this.borderColor,
    required this.specialButtonColor,
    required this.disabledCardColor,
    required this.shimmerBase, // Базовый цвет для скелетон-лоадера
    required this.shimmerHighlight, // Подсветка для скелетон-лоадера
    required this.inputBackground, // Фон текстовых полей
    required this.listItemBackground, // Фон элементов списка
    required this.surface, // Цвет поверхности
    required this.progressBackground, // Фон прогресс-бара
  });

  // Светлая тема
  static AppColors light() {
    return AppColors(
      backgroundColor: Colors.white,
      textColor: Colors.black,
      appBarColor: const Color.fromARGB(255, 255, 255, 255),
      iconColor: Colors.black,
      cardColor: Colors.grey[100]!,
      dividerColor: Colors.grey[300]!,
      primaryColor: const Color(0xFF692FFF), // #692FFF
      secondaryColor: const Color(0xFFC146FE), // #C146FE
      buttonColor: const Color(0xFFFFC846), // #FFC846
      buttonTextColor: Colors.white,
      errorColor: const Color(0xFFA92B2B), // #A92B2B
      successColor: const Color(0xFF56D7FF), // #56D7FF
      hintColor: Colors.grey[500]!,
      disabledColor: Colors.grey[400]!,
      shadowColor: Colors.black.withOpacity(0.1),
      overlayColor: const Color(0xFF0DD0E7), // #0DD0E7
      accentColor: const Color(0xFFFF5722), // Пример цвета для accentColor
      callBackgroundColor: Colors.white,
      borderColor: Colors.grey[400]!, // Цвет границ для светлой темы
      specialButtonColor: const Color(0xFF4CAF50), // Зелёный для Enter
      disabledCardColor: Colors.grey.shade50,
      shimmerBase: Colors.grey[300]!, // Базовый цвет для скелетон-лоадера
      shimmerHighlight: Colors.grey[100]!, // Подсветка для скелетон-лоадера
      inputBackground: Colors.grey[200]!, // Фон текстовых полей
      listItemBackground: Colors.grey[50]!, // Фон элементов списка
      surface: Colors.white, // Цвет поверхности
      progressBackground: Colors.grey[200]!, // Фон прогресс-бара
    );
  }

  // Темная тема
  static AppColors dark() {
    return AppColors(
      backgroundColor: const Color(0xFF121212), // Глубокий тёмно-серый
      textColor: const Color(0xFFE0E0E0), // Светло-серый для текста
      appBarColor: const Color(0xFF1E1E1E), // Тёмный цвет для AppBar
      iconColor: const Color(0xFFE0E0E0), // Светло-серый для иконок
      cardColor: const Color(0xFF1E1E1E), // Тёмный цвет для карточек
      dividerColor: const Color(0xFF333333), // Серый для разделителей
      primaryColor: const Color(0xFFBB86FC), // Фиолетовый акцентный цвет
      secondaryColor: const Color(0xFF03DAC6), // Бирюзовый акцентный цвет
      buttonColor: const Color(0xFFBB86FC), // Фиолетовый для кнопок
      buttonTextColor: Colors.black, // Тёмный текст на кнопках
      errorColor: const Color(0xFFCF6679), // Красный для ошибок
      successColor: const Color(0xFF03DAC6), // Бирюзовый для успешных действий
      hintColor: const Color(0xFF757575), // Серый для подсказок
      disabledColor: const Color(0xFF424242), // Серый для отключённых элементов
      shadowColor: Colors.black.withOpacity(0.5), // Тёмные тени
      overlayColor:
          const Color(0xFF1E1E1E).withOpacity(0.8), // Полупрозрачный оверлей
      accentColor: const Color(0xFFFF9800), // Пример цвета для accentColor
      callBackgroundColor: const Color(0xFF1E1E1E),
      borderColor: const Color(0xFF424242), // Цвет границ для темной темы
      specialButtonColor: const Color(0xFF43A047), // Тёмно-зелёный для Enter
      disabledCardColor: Colors.grey.shade50,
      shimmerBase: const Color(0xFF222222), // Базовый цвет для скелетон-лоадера
      shimmerHighlight:
          const Color(0xFF333333), // Подсветка для скелетон-лоадера
      inputBackground: const Color(0xFF1E1E1E), // Фон текстовых полей
      listItemBackground: const Color(0xFF1E1E1E), // Фон элементов списка
      surface: const Color(0xFF1E1E1E), // Цвет поверхности
      progressBackground: const Color(0xFF222222), // Фон прогресс-бара
    );
  }
}
