import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart'; // Импортируем пакет для открытия URL
import '../../../../core/utils/AppColors.dart';
import '../../data/services/theme_manager.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  _PremiumPageState createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String _selectedPlan = 'Ежемесячно';

  void _selectPlan(String plan) {
    setState(() {
      _selectedPlan = plan;
    });
    print('Выбран план: $_selectedPlan');
  }

  String _getButtonText() {
    if (_selectedPlan == 'Раз в 3 месяца') {
      return 'Подключить за 249 ЩЩ (раз в 3 месяца)';
    } else if (_selectedPlan == 'Ежемесячно') {
      return 'Подключить за 99 ЩЩ (ежемесячно)';
    }
    return 'Подписаться';
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Не удалось открыть $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ЩЩ Premium',
          style: TextStyle(color: colors.textColor),
        ),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Lottie.asset(
                    'assets/lottie/star.json',
                    width: 250,
                    height: 250,
                  ),
                ),
                Text(
                  'ЩЩ Premium',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Множество эксклюзивных функций с подпиской ЩЩ Premium',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Card(
                    color: colors.cardColor,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            _selectedPlan == 'Раз в 3 месяца'
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: _selectedPlan == 'Раз в 3 месяца'
                                ? colors.primaryColor
                                : colors.iconColor,
                          ),
                          title: Text(
                            'Раз в 3 месяца',
                            style: TextStyle(
                              fontSize: 18,
                              color: colors.textColor,
                            ),
                          ),
                          trailing: Text(
                            '249 ЩЩ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          onTap: () {
                            _selectPlan('Раз в 3 месяца');
                          },
                        ),
                        Divider(color: colors.dividerColor),
                        ListTile(
                          leading: Icon(
                            _selectedPlan == 'Ежемесячно'
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: _selectedPlan == 'Ежемесячно'
                                ? colors.primaryColor
                                : colors.iconColor,
                          ),
                          title: Text(
                            'Ежемесячно',
                            style: TextStyle(
                              fontSize: 18,
                              color: colors.textColor,
                            ),
                          ),
                          trailing: Text(
                            '99 ЩЩ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          onTap: () {
                            _selectPlan('Ежемесячно');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  child: Card(
                    color: colors.cardColor,
                    child: Column(
                      children: [
                        _buildFeatureTile(
                          Icons.favorite_border_rounded,
                          'Поддержка авторов',
                          'Ваша подписка помогает поддерживать авторов контента.',
                          colors,
                        ),
                        Divider(color: colors.dividerColor),
                        _buildFeatureTile(
                          Icons.star_border_purple500_rounded,
                          'Значок подписчика',
                          'Получите специальный значок подписчика.',
                          colors,
                        ),
                        Divider(color: colors.dividerColor),
                        _buildFeatureTile(
                          Icons.emoji_emotions_rounded,
                          'Эмодзи-статус',
                          'Выразите своё настроение с помощью эмодзи-статуса.',
                          colors,
                        ),
                        Divider(color: colors.dividerColor),
                        _buildFeatureTile(
                          Icons.now_wallpaper,
                          'Анимации поверх обоев',
                          'Наслаждайтесь анимациями, отображаемыми поверх обоев.',
                          colors,
                        ),
                        Divider(color: colors.dividerColor),
                        _buildFeatureTile(
                          Icons.apps_rounded,
                          'Ранний доступ к мини-приложениям',
                          'Получайте ранний доступ к новым мини-приложениям.',
                          colors,
                        ),
                        Divider(color: colors.dividerColor),
                        _buildFeatureTile(
                          Icons.lock_open_rounded,
                          'Доступ к ограниченным приложениям',
                          'Откройте для себя приложения, доступные только подписчикам.',
                          colors,
                        ),
                        Divider(color: colors.dividerColor),
                        _buildFeatureTile(
                          Icons.file_upload_rounded,
                          'Увеличенные лимиты на загружаемые файлы',
                          'Загружайте больше файлов с увеличенными лимитами.',
                          colors,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withOpacity(0.7),
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              'Оформляя подписку ЩЩ Premium, Вы принимаете условия ',
                        ),
                        TextSpan(
                          text: 'Пользовательского соглашения',
                          style: TextStyle(color: colors.primaryColor),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchUrl('https://example.com/user-agreement');
                            },
                        ),
                        TextSpan(
                          text: ' и ',
                        ),
                        TextSpan(
                          text: 'Политики конфиденциальности',
                          style: TextStyle(color: colors.primaryColor),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchUrl('https://example.com/privacy-policy');
                            },
                        ),
                        TextSpan(
                          text: '.',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedPlan.isNotEmpty) {
                  print('Подписка на план: $_selectedPlan');
                  buy(_selectedPlan);
                } else {
                  print('Пожалуйста, выберите план.');
                }
              },
              icon: Icon(Icons.star, color: colors.buttonTextColor),
              label: Text(
                _getButtonText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.buttonTextColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.buttonColor,
                padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget _buildFeatureTile(
      IconData icon, String title, String description, AppColors colors) {
    return ListTile(
      leading: Icon(icon, color: colors.iconColor, size: 30),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: colors.textColor,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 14,
          color: colors.textColor.withOpacity(0.7),
        ),
      ),
    );
  }

  void _showPaymentUnavailableDialog(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.backgroundColor,
          title: Text(
            'Оплата временно недоступна',
            style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'В данный момент оплата не работает. Вы можете поддержать авторов, перейдя по ссылке и указав свой username, и получить премиум или другой подарок.',
            style: TextStyle(
              color: colors.textColor,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Поддержать'),
              onPressed: () => buy(_selectedPlan),
            ),
          ],
        );
      },
    );
  }

  void buy(String _selectedPlan) {
    if (_selectedPlan == 'Раз в 3 месяца') {
      //TODO{Сделать через ruStore}
    } else if (_selectedPlan == 'Ежемесячно') {
      //TODO{Сделать через ruStore}
    }
  }
}
