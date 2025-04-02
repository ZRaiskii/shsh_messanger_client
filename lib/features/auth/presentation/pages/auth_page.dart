import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/core/utils/AppColors.dart';
import 'package:shsh_social/features/settings/data/services/theme_manager.dart';
import '../widgets/auth_card.dart';
import '../../../main/presentation/pages/main_page.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import '../../../../core/widgets/new_year/new_year_snowfall.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/managers/auth_data_manager.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthPage(),
    );
  }
}

class _AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  bool _isSnowfallEnabled = false;

  late final AuthDataManager _authDataManager;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final SwiperController _swiperController = SwiperController();

  @override
  void initState() {
    super.initState();

    // Инициализация зависимостей для AuthDataManager
    final remoteDataSource = AuthRemoteDataSourceImpl(client: http.Client());
    final sharedPreferences =
        SharedPreferences.getInstance(); // Асинхронный вызов
    final localDataSource = AuthLocalDataSourceImpl();

    _authDataManager = AuthDataManager(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(_animationController);
  }

  void _onPageChanged(int index) {
    index == 1
        ? _animationController.forward()
        : _animationController.reverse();
  }

  void _toggleSnowfall() {
    setState(() {
      _isSnowfallEnabled = !_isSnowfallEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: Stack(
        children: [
          if (_isSnowfallEnabled)
            NewYearSnowfall(
              isPlaying: false,
              animationType: "snowflakes",
              child: Container(),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                _buildAnimatedTitle(),
                const SizedBox(height: 24),
                Expanded(
                  child: Stack(
                    children: [
                      Swiper(
                        controller: _swiperController,
                        itemCount: 2,
                        onIndexChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          return index == 0
                              ? AuthCard(
                                  title: 'Вход',
                                  isLogin: true,
                                  onTap: () {
                                    _swiperController.next();
                                  },
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  authDataManager: _authDataManager,
                                )
                              : AuthCard(
                                  title: 'Регистрация',
                                  isLogin: false,
                                  onTap: () {
                                    _swiperController.previous();
                                  },
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  usernameController: _usernameController,
                                  confirmPasswordController:
                                      _confirmPasswordController,
                                  authDataManager: _authDataManager,
                                );
                        },
                        pagination: const SwiperPagination(
                          builder: DotSwiperPaginationBuilder(
                              activeColor: Colors.indigo, color: Colors.grey),
                        ),
                        control: const SwiperControl(),
                      ),
                      if (Platform.isWindows)
                        Positioned(
                          top: screenHeight * 0.4,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios,
                                    color: Colors.indigo),
                                onPressed: () {
                                  _swiperController.previous();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    color: Colors.indigo),
                                onPressed: () {
                                  _swiperController.next();
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildBottomLinks(),
              ],
            ),
          ),
          Positioned(
            top: 28,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0, end: 1).animate(animation),
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                key: ValueKey(isWhiteNotifier.value),
                onTap: toggleTheme,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWhiteNotifier.value
                        ? Colors.grey[200]
                        : Colors.grey[800],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isWhiteNotifier.value ? Icons.wb_sunny : Icons.nights_stay,
                    color: isWhiteNotifier.value
                        ? Colors.orangeAccent
                        : Colors.blue[200],
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void toggleTheme() async {
    setState(() {
      isWhiteNotifier.value = !isWhiteNotifier.value;
    });
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Text(
          'ЩЩ',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: _colorAnimation.value,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomLinks() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => debugPrint('Забыл пароль нажато'),
        child: const Text(
          'Забыл пароль?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    _swiperController.dispose();
    super.dispose();
  }
}
