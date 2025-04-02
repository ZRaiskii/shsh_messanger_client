import 'package:flutter/material.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../../core/version_manager.dart';
import '../../../settings/data/services/theme_manager.dart';

class DownloadUpdatePage extends StatefulWidget {
  final String platform; // "android", "windows" или другая платформа

  const DownloadUpdatePage({Key? key, required this.platform})
      : super(key: key);

  @override
  _DownloadUpdatePageState createState() => _DownloadUpdatePageState();
}

class _DownloadUpdatePageState extends State<DownloadUpdatePage> {
  bool _isDownloading = false; // Состояние загрузки

  @override
  Widget build(BuildContext context) {
    final versionManager = VersionManager();

    return ValueListenableBuilder<bool>(
      valueListenable: isWhiteNotifier,
      builder: (context, isWhite, child) {
        final colors = isWhite ? AppColors.light() : AppColors.dark();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              widget.platform == "android"
                  ? 'Загрузка обновления'
                  : 'Загрузка установщика',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            backgroundColor: colors.appBarColor,
            iconTheme: IconThemeData(color: colors.iconColor),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    size: 64,
                    color: colors.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.platform == "android"
                        ? 'Загрузка новой версии...'
                        : 'Загрузка Windows-установщика...',
                    style: TextStyle(fontSize: 18, color: colors.textColor),
                  ),
                  const SizedBox(height: 20),

                  // Индикатор загрузки
                  if (_isDownloading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.primaryColor,
                      ),
                    ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isDownloading
                        ? null // Делаем кнопку неактивной во время загрузки
                        : () async {
                            setState(() {
                              _isDownloading = true; // Начинаем загрузку
                            });

                            try {
                              if (widget.platform == "android") {
                                await versionManager
                                    .downloadAndInstallApk(context);
                              } else if (widget.platform == "windows") {
                                await versionManager
                                    .downloadWindowsInstaller(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Платформа не поддерживается')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Ошибка при загрузке: $e')),
                              );
                            } finally {
                              setState(() {
                                _isDownloading = false; // Завершаем загрузку
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 32.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      backgroundColor: colors.primaryColor,
                    ),
                    child: Text(
                      widget.platform == "android"
                          ? "Начать загрузку"
                          : "Скачать установщик",
                      style: TextStyle(fontSize: 16, color: colors.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: colors.backgroundColor,
        );
      },
    );
  }
}
