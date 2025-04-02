import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../mini_apps_page.dart';
import '../../../../../core/utils/AppColors.dart';
import '../../../../settings/data/services/theme_manager.dart';

class MiniAppContainer extends StatelessWidget {
  final Widget miniApp;
  final MiniAppCard appInfo;

  const MiniAppContainer({
    required this.miniApp,
    required this.appInfo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    final focusNode = FocusNode();

    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (RawKeyEvent event) {
        if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appInfo.title,
            style: TextStyle(color: colors.textColor),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.iconColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: colors.appBarColor,
          iconTheme: IconThemeData(color: colors.iconColor),
          actions: [
            IconButton(
              icon: Icon(Icons.info, color: colors.iconColor),
              onPressed: () => _showAppInfo(context),
            ),
          ],
        ),
        backgroundColor: colors.backgroundColor,
        body: Focus(
          autofocus: true, // Автоматически фокусируется на виджете
          child: miniApp,
        ),
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.center,
        child: AppInfoDialog(
          appInfo: appInfo,
          colors: colors,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, -0.2), end: Offset.zero)
              .animate(anim1),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  List<Widget> _buildInfoRow(String label, String value) {
    return [
      RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}

class AppInfoDialog extends StatelessWidget {
  final MiniAppCard appInfo;
  final AppColors colors;
  final VoidCallback onClose;

  const AppInfoDialog({
    required this.appInfo,
    required this.colors,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Добавлено получение темы

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и кнопка закрытия
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appInfo.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      // Исправлено
                      color: colors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.iconColor),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Основное содержимое
            if (appInfo.imageUrl != null)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(appInfo.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowColor.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              appInfo.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                // Исправлено
                color: colors.textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Метаданные
            _buildSection(context, 'Основная информация', Icons.info_outline, [
              _buildListItem(Icons.category, 'Тип',
                  appInfo.appType == AppType.internal ? 'Внутреннее' : 'Веб'),
              _buildListItem(
                  Icons.engineering,
                  'Разработчик',
                  appInfo.developerType == DeveloperType.internal
                      ? 'Внутренняя команда'
                      : appInfo.developerName ?? 'Сторонний'),
              if (appInfo.version != null)
                _buildListItem(Icons.update, 'Версия', appInfo.version!),
            ]),
            const SizedBox(height: 16),

            _buildSection(context, 'Технические данные', Icons.build, [
              _buildListItem(Icons.phone_android, 'Платформы',
                  appInfo.supportedPlatforms.map((p) => p.name).join(', ')),
              if (appInfo.releaseDate != null)
                _buildListItem(Icons.calendar_today, 'Релиз',
                    DateFormat('dd.MM.yyyy').format(appInfo.releaseDate!)),
              if (appInfo.permissions?.isNotEmpty ?? false)
                _buildListItem(Icons.security, 'Разрешения',
                    appInfo.permissions!.join(', ')),
            ]),
            const SizedBox(height: 16),

            // Статус
            if (appInfo.additionalData?['coming_soon'] == true)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Скоро будет доступно!',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      List<Widget> children) {
    final theme = Theme.of(context); // Добавлено получение темы
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colors.primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                // Исправлено
                color: colors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: colors.iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    // Исправлено: используем colors вместо theme
                    color: colors.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    // Исправлено: используем colors вместо theme
                    color: colors.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
