import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../../core/utils/AppColors.dart';

import '../../../settings/data/services/theme_manager.dart'; // Импортируем AppColors

class FullScreenImageView extends StatefulWidget {
  final String imageUrl;
  final DateTime timestamp;
  final VoidCallback onClose;

  const FullScreenImageView({
    super.key,
    required this.imageUrl,
    required this.timestamp,
    required this.onClose,
  });

  @override
  _FullScreenImageViewState createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  bool _isAppBarVisible = true;

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return WillPopScope(
      onWillPop: () async {
        widget.onClose();
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        body: Stack(
          children: [
            // Фото на весь экран
            Center(
              child: PhotoView(
                imageProvider: NetworkImage(widget.imageUrl),
                backgroundDecoration:
                    BoxDecoration(color: colors.backgroundColor),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.imageUrl),
              ),
            ),

            // Обработчик нажатия на экран
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior
                    .translucent, // Разрешаем PhotoView обрабатывать жесты
                onTap: () {
                  setState(() {
                    _isAppBarVisible = !_isAppBarVisible;
                  });
                },
              ),
            ),

            // AppBar, который появляется и исчезает
            if (_isAppBarVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: colors.appBarColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colors.iconColor,
                    ),
                    onPressed: () {
                      widget.onClose();
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'ru_RU')
                        .format(widget.timestamp),
                    style: TextStyle(color: colors.textColor),
                  ),
                  actions: [
                    PopupMenuButton<int>(
                      iconColor: colors.iconColor,
                      onSelected: (item) => _handleMenuSelection(context, item),
                      itemBuilder: (context) => [
                        PopupMenuItem<int>(
                          value: 0,
                          child: Text(
                            'Скопировать ссылку',
                            style: TextStyle(color: colors.textColor),
                          ),
                        ),
                        PopupMenuItem<int>(
                          value: 1,
                          child: Text(
                            'Скачать',
                            style: TextStyle(color: colors.textColor),
                          ),
                        ),
                      ],
                      color: colors.cardColor,
                      elevation: 4.0,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, int item) {
    Navigator.of(context).pop(); // Закрываем popup меню после выбора
    switch (item) {
      case 0:
        Clipboard.setData(ClipboardData(text: widget.imageUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ссылка скопирована')),
        );
        break;
      case 1:
        _downloadImage(context);
        break;
    }
    widget
        .onClose(); // Уведомляем родительский виджет о закрытии эффекта размытия
  }

  Future<void> _downloadImage(BuildContext context) async {
    final response = await http.get(Uri.parse(widget.imageUrl));
    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File('${documentDirectory.path}/downloaded_image.jpg');
    await file.writeAsBytes(response.bodyBytes);
    final context = navigatorKey.currentContext!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Изображение скачано')),
    );
  }
}
