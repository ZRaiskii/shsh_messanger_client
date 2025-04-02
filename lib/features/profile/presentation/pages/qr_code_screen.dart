import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart'; // Для загрузки аватара

class QRCodeScreen extends StatelessWidget {
  final String userId;
  final String avatarUrl; // URL аватара пользователя
  final String username; // Имя пользователя

  const QRCodeScreen({
    required this.userId,
    required this.avatarUrl,
    required this.username,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = '{::($userId)/openChat}'; // Формат ссылки

    return ValueListenableBuilder<bool>(
      valueListenable: isWhiteNotifier,
      builder: (context, isWhite, child) {
        // Получаем цвета в зависимости от темы
        final colors = isWhite ? AppColors.light() : AppColors.dark();

        return Scaffold(
          backgroundColor: colors.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.iconColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Общий Stack для карточки и аватарки
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none, // Отключаем обрезку
                  children: [
                    // Карточка с QR-кодом
                    Container(
                      width: 300,
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.white, // Белый цвет карточки
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // QR-код
                          Positioned(
                            top: 50, // Уменьшенный отступ сверху
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Скругление QR-кода
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      10), // Скругление краёв
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 220.0, // Увеличенный размер QR-кода
                                    dataModuleStyle: QrDataModuleStyle(
                                      color:
                                          Colors.black, // Чёрный цвет QR-кода
                                      dataModuleShape: QrDataModuleShape.square,
                                    ),
                                  ),
                                ),
                                // Скруглённая иконка поверх QR-кода
                                _buildRoundedIcon(colors),
                              ],
                            ),
                          ),

                          // Имя пользователя
                          Positioned(
                            bottom: 20,
                            child: Text(
                              username,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Чёрный цвет текста
                                letterSpacing: 1.2, // Улучшение стиля текста
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Аватарка (накладывается поверх карточки)
                    Positioned(
                      top:
                          -40, // Аватарка наполовину на карточке, наполовину на фоне
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Colors.transparent, // Белая рамка для аватарки
                            width: 5,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Text(
                  'Отсканируйте этот код, чтобы начать чат',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textColor, // Цвет текста из темы
                    fontSize: 16, // Увеличенный размер текста
                    letterSpacing: 1.1, // Улучшение стиля текста
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Виджет для скруглённой иконки
  Widget _buildRoundedIcon(AppColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // Закругление углов
      child: Image.asset(
        'assets/icons/icon.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }
}
