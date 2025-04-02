import 'dart:ui';

class AppColors {
  static AppColors light() {
    return AppColors._(
      backgroundColor: const Color(0xFFF5F5F5), // Светло-серый фон
      cardColor: const Color(0xFFFFFFFF), // Белая карточка
      textColor: const Color(0xFF333333), // Темно-серый текст
      buttonColor: const Color(0xFF6200EE), // Фиолетовая кнопка
      iconColor: const Color(0xFFFFFFFF), // Белые иконки
      shadowColor: const Color(0xFF000000).withOpacity(0.1), // Легкая тень
      shimmerHighlight: const Color(0xFFE0E0E0), // Светлый блик
    );
  }

  static AppColors dark() {
    return AppColors._(
      backgroundColor: const Color(0xFF121212), // Темно-серый фон
      cardColor: const Color(0xFF1E1E1E), // Темная карточка
      textColor: const Color(0xFFFFFFFF), // Белый текст
      buttonColor: const Color(0xFFBB86FC), // Фиолетовая кнопка
      iconColor: const Color(0xFFFFFFFF), // Белые иконки
      shadowColor: const Color(0xFF000000).withOpacity(0.2), // Легкая тень
      shimmerHighlight: const Color(0xFF424242), // Темный блик
    );
  }

  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color buttonColor;
  final Color iconColor;
  final Color shadowColor;
  final Color shimmerHighlight;

  AppColors._({
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.buttonColor,
    required this.iconColor,
    required this.shadowColor,
    required this.shimmerHighlight,
  });
}
