import 'package:flutter/material.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';
import 'download_update_page.dart';

class OutdatedVersionPage extends StatelessWidget {
  final String errorMessage;
  final String platform;

  const OutdatedVersionPage({
    Key? key,
    required this.errorMessage,
    required this.platform,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isWhiteNotifier,
      builder: (context, isWhite, child) {
        final colors = isWhite ? AppColors.light() : AppColors.dark();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Обновление приложения',
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
                    Icons.system_update,
                    size: 64,
                    color: colors.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    errorMessage,
                    style: TextStyle(fontSize: 18, color: colors.textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DownloadUpdatePage(platform: platform),
                        ),
                      );
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
                      platform == "android"
                          ? "Обновить приложение"
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
