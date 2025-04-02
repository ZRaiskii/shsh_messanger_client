import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class ClickerGamePage extends StatefulWidget {
  @override
  _ClickerGamePageState createState() => _ClickerGamePageState();
}

class _ClickerGamePageState extends State<ClickerGamePage>
    with TickerProviderStateMixin {
  int _coins = 0;
  int _memsBought = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<bool> _memsPurchased = [false, false, false];
  double _rotationTurns = 0.0;
  double _scaleFactor = 1.0;
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
  late AnimationController _gradientAnimationController;
  late Animation<Color?> _gradientAnimation;

  // Список достижений (20 штук)
  List<Map<String, dynamic>> achievements = [
    {
      'name': 'Начинающий',
      'targetCoins': 10,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Продвинутый',
      'targetCoins': 50,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Профессионал',
      'targetCoins': 100,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Миллионер',
      'targetCoins': 1000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Коллекционер',
      'targetCoins': 0,
      'targetMems': 5,
      'completed': false
    },
    {
      'name': 'Охотник за мемами',
      'targetCoins': 0,
      'targetMems': 10,
      'completed': false
    },
    {
      'name': 'Эксперт по кликам',
      'targetCoins': 500,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Собиратель мемов',
      'targetCoins': 0,
      'targetMems': 15,
      'completed': false
    },
    {
      'name': 'Тысячник',
      'targetCoins': 1000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Мастер кликов',
      'targetCoins': 2000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Знаток мемов',
      'targetCoins': 0,
      'targetMems': 20,
      'completed': false
    },
    {
      'name': 'Богатей',
      'targetCoins': 5000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Всезнайка',
      'targetCoins': 0,
      'targetMems': 25,
      'completed': false
    },
    {
      'name': 'Гигант кликов',
      'targetCoins': 10000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Король мемов',
      'targetCoins': 0,
      'targetMems': 30,
      'completed': false
    },
    {
      'name': 'Мега-коллекционер',
      'targetCoins': 0,
      'targetMems': 35,
      'completed': false
    },
    {
      'name': 'Легенда кликов',
      'targetCoins': 50000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Император мемов',
      'targetCoins': 0,
      'targetMems': 40,
      'completed': false
    },
    {
      'name': 'Миллиардер',
      'targetCoins': 100000,
      'targetMems': 0,
      'completed': false
    },
    {
      'name': 'Бессмертный коллекционер',
      'targetCoins': 0,
      'targetMems': 50,
      'completed': false
    },
  ];

  final List<OverlayEntry> _overlayEntries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    _animationController.repeat(reverse: true);

    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(_gradientAnimationController)
      ..addListener(() {
        setState(() {});
      });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins = prefs.getInt('coins') ?? 0;
      _memsBought = prefs.getInt('memsBought') ?? 0;
      _memsPurchased = prefs
              .getStringList('memsPurchased')
              ?.map((e) => e == 'true')
              .toList() ??
          [false, false, false];
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('coins', _coins);
    prefs.setInt('memsBought', _memsBought);
    prefs.setStringList(
        'memsPurchased', _memsPurchased.map((e) => e.toString()).toList());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gradientAnimationController.dispose();
    super.dispose();
  }

  void _incrementCoins() {
    final random = Random();
    final shouldFlip = random.nextInt(1000) < 10;

    setState(() {
      _coins++;
      _scaleFactor = 1.1;
      if (shouldFlip) {
        _rotationTurns += 3;
      }
      for (var achievement in achievements) {
        if ((_coins >= achievement['targetCoins'] ||
                achievement['targetCoins'] == 0) &&
            (_memsBought >= achievement['targetMems'] ||
                achievement['targetMems'] == 0) &&
            !achievement['completed']) {
          achievement['completed'] = true;
          _confettiController.play();
        }
      }
    });

    // Сброс увеличения через короткое время
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _scaleFactor = 1.0;
      });
    });

    _saveData();
    _showPlusOneAnimation();
  }

  void _showPlusOneAnimation() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final random = Random();
    final offset = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset:
                  Offset(0, -50 * _animation.value), // Поднимаем текст вверх
              child: Transform.scale(
                scale: 1 + (0.5 * _animation.value), // Увеличиваем текст
                child: Opacity(
                  opacity: _animation.value,
                  child: Text(
                    '+1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Простой цвет текста
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    _overlayEntries.add(overlayEntry);
    Overlay.of(context)?.insert(overlayEntry);
    Future.delayed(Duration(milliseconds: 500), () {
      overlayEntry.remove();
      _overlayEntries.remove(overlayEntry);
    });
  }

  void _buyMem(int index, int cost) {
    if (_coins >= cost && !_memsPurchased[index]) {
      setState(() {
        _coins -= cost;
        _memsBought++;
        _memsPurchased[index] = true;
        _checkAchievements();
      });
      _saveData();
    }
  }

  void _checkAchievements() {
    for (var achievement in achievements) {
      if ((_coins >= achievement['targetCoins'] ||
              achievement['targetCoins'] == 0) &&
          (_memsBought >= achievement['targetMems'] ||
              achievement['targetMems'] == 0) &&
          !achievement['completed']) {
        achievement['completed'] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gradientAnimation.value ?? colors.backgroundColor,
                colors.accentColor,
              ],
            ),
          ),
        ),
        Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: colors.iconColor),
                        SizedBox(width: 8.0),
                        Text(
                          '$_coins',
                          style: TextStyle(
                            color: colors.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: colors.iconColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemShopPage(
                            coins: _coins,
                            buyMem: _buyMem,
                            memsPurchased: _memsPurchased,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _incrementCoins,
                        child: AnimatedRotation(
                          turns: _rotationTurns,
                          duration: Duration(milliseconds: 500),
                          child: AnimatedScale(
                            scale: _scaleFactor,
                            duration: Duration(milliseconds: 100),
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: Offset(0, 7),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    colors.primaryColor,
                                    colors.accentColor
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                image: DecorationImage(
                                  image: AssetImage('assets/icons/icon.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.0),
                    ...achievements.map((achievement) =>
                        _buildAchievementCard(achievement, colors)),
                  ],
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
      Map<String, dynamic> achievement, AppColors colors) {
    double progress = achievement['targetCoins'] > 0
        ? (_coins / achievement['targetCoins']).clamp(0.0, 1.0)
        : (_memsBought / achievement['targetMems']).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      color:
          achievement['completed'] ? Colors.green.shade100 : colors.cardColor,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        leading: Icon(
          Icons.star,
          color: achievement['completed'] ? Colors.yellow : colors.iconColor,
        ),
        title: Text(
          achievement['name'],
          style: TextStyle(
            color: achievement['completed'] ? Colors.green : colors.textColor,
            fontWeight:
                achievement['completed'] ? FontWeight.bold : FontWeight.normal,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Цель: ${achievement['targetCoins']} монет, ${achievement['targetMems']} мемов',
              style: TextStyle(
                color: achievement['completed']
                    ? Colors.green
                    : colors.textColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8.0),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.cardColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                achievement['completed'] ? Colors.green : colors.iconColor,
              ),
            ),
          ],
        ),
        trailing: achievement['completed']
            ? Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }
}

class MemShopPage extends StatelessWidget {
  final int coins;
  final Function(int, int) buyMem;
  final List<bool> memsPurchased;

  MemShopPage(
      {super.key,
      required this.coins,
      required this.buyMem,
      required this.memsPurchased});

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Магазин мемов',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Icon(Icons.monetization_on, color: colors.iconColor),
            SizedBox(width: 8.0),
            Text(
              '$coins',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: colors.appBarColor,
        iconTheme: IconThemeData(color: colors.iconColor),
      ),
      backgroundColor: colors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildMemCard(
              context,
              'assets/mini_apps/images/butovskaya_goat.png',
              'Бутовская коза',
              'Эта коза добавит вам +1 к крутости \nи -1 к здравому смыслу!',
              10,
              0, // Индекс мема
              colors,
              buyMem,
            ),
            SizedBox(height: 16.0),
            _buildMemCard(
              context,
              'assets/icons/icon.png',
              'Что такое ЩЩ?',
              'Может это щавелевые ЩИ???',
              50,
              1, // Индекс мема
              colors,
              buyMem,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemCard(
    BuildContext context,
    String imageUrl,
    String title,
    String description,
    int cost,
    int index,
    AppColors colors,
    Function(int, int) buyMem,
  ) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: colors.cardColor,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Image.asset(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.title, color: colors.textColor),
                    SizedBox(width: 8.0),
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: memsPurchased[index]
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(Icons.description, color: colors.textColor),
                    SizedBox(width: 8.0),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 16,
                        decoration: memsPurchased[index]
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed:
                      memsPurchased[index] ? null : () => buyMem(index, cost),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        memsPurchased[index] ? Colors.grey : colors.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    memsPurchased[index] ? 'Куплено' : 'Купить за $cost монет',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
