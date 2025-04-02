import 'package:flutter/material.dart';
import 'package:shsh_social/core/utils/AppColors.dart';
import 'package:shsh_social/features/settings/data/services/theme_manager.dart';
import '../../../../core/widgets/custom/custom_button.dart';
import '../../../../core/widgets/custom/custom_text_field.dart';
import '../../data/managers/auth_data_manager.dart';

class AuthCard extends StatefulWidget {
  final String title;
  final bool isLogin;
  final VoidCallback onTap;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? usernameController;
  final TextEditingController? confirmPasswordController;

  final AuthDataManager _authDataManager;

  const AuthCard({
    required this.title,
    required this.isLogin,
    required this.onTap,
    required this.emailController,
    required this.passwordController,
    required AuthDataManager authDataManager,
    this.usernameController,
    this.confirmPasswordController,
    super.key,
  }) : _authDataManager = authDataManager;

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _usernameError;
  String? _confirmPasswordError;

  late AppColors colors;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    final passwordRegex = RegExp(
      r"^(?=.*[A-Za-z])"
              r"(?=.*\d)"
              r"(?=.*[@$!%*#?&^(){}\[\]:;<>,.|~`\" +
          '"' +
          '\\+=_-])'
              r"[A-Za-z\d@$!%*#?&^(){}\[\]:;<>,.|~`\" +
          '"' +
          "'" +
          "\\+=_-]{8,}\$",
    );
    return passwordRegex.hasMatch(password);
  }

  bool _validateUsername(String username) {
    return username.length >= 5;
  }

  void _validateFields() {
    bool isValid = true;

    if (!_validateEmail(widget.emailController.text)) {
      _emailError = 'Введите корректный email';
      isValid = false;
    } else {
      _emailError = null;
    }

    if (!widget.isLogin) {
      if (!_validatePassword(widget.passwordController.text)) {
        _passwordError =
            'Пароль должен содержать минимум 8 символов, включая 1 букву, 1 цифру и 1 спецсимвол';
        isValid = false;
      } else {
        _passwordError = null;
      }

      if (!_validateUsername(widget.usernameController?.text ?? '')) {
        _usernameError = 'Никнейм должен содержать минимум 5 символов';
        isValid = false;
      } else {
        _usernameError = null;
      }

      if (widget.passwordController.text !=
          widget.confirmPasswordController?.text) {
        _confirmPasswordError = 'Пароли не совпадают';
        isValid = false;
      } else {
        _confirmPasswordError = null;
      }
    }

    if (!isValid) {
      setState(() {});
      throw Exception('Validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    return Center(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor,
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: colors.cardColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crooker',
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: widget.emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    errorText: _emailError,
                    helperText: 'Пример: example@mail.com',
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  if (!widget.isLogin)
                    _buildTextField(
                      controller: widget.usernameController!,
                      hintText: 'Имя пользователя',
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person,
                      errorText: _usernameError,
                      helperText: 'Минимум 5 символов',
                      validator: (value) => _validateUsername(value),
                    ),
                  if (!widget.isLogin) const SizedBox(height: 12),
                  _buildTextField(
                    controller: widget.passwordController,
                    hintText: 'Пароль',
                    keyboardType: TextInputType.visiblePassword,
                    prefixIcon: Icons.lock,
                    obscureText: !_isPasswordVisible,
                    showVisibilityToggle: true,
                    onVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    errorText: _passwordError,
                    helperText:
                        'Минимум 8 символов, включая буквы, цифры и спецсимволы',
                    validator: _validatePassword,
                  ),
                  if (!widget.isLogin) const SizedBox(height: 12),
                  if (!widget.isLogin)
                    _buildTextField(
                      controller: widget.confirmPasswordController!,
                      hintText: 'Подтвердите пароль',
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: Icons.lock,
                      obscureText: !_isConfirmPasswordVisible,
                      showVisibilityToggle: true,
                      onVisibilityToggle: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      errorText: _confirmPasswordError,
                      helperText: 'Пароли должны совпадать',
                      validator: (value) =>
                          value == widget.passwordController.text,
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colors.primaryColor,
                          ),
                        )
                      : CustomButton(
                          onPressed: () async {
                            try {
                              _validateFields();
                            } catch (e) {
                              return;
                            }

                            setState(() => _isLoading = true);

                            try {
                              if (widget.isLogin) {
                                await widget._authDataManager.login(
                                  email: widget.emailController.text,
                                  password: widget.passwordController.text,
                                );
                              } else {
                                await widget._authDataManager.register(
                                  email: widget.emailController.text,
                                  username:
                                      widget.usernameController?.text ?? '',
                                  password: widget.passwordController.text,
                                  confirmPassword:
                                      widget.confirmPasswordController?.text ??
                                          '',
                                );
                              }

                              Navigator.of(context)
                                  .pushReplacementNamed('/main');
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: colors.errorColor,
                                ),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                          text: widget.title,
                          colors: colors,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    bool obscureText = false,
    bool showVisibilityToggle = false,
    VoidCallback? onVisibilityToggle,
    String? errorText,
    required String helperText,
    required Function(String) validator,
  }) {
    bool isValid = errorText == null;
    colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    // Осветление фона для тёмной темы
    Color adjustedInputBackground = isWhiteNotifier.value
        ? colors.inputBackground
        : _lightenColor(colors.inputBackground, 0.1); // Осветляем на 10%

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: (value) {
            setState(() {
              if (!validator(value)) {
                errorText = 'Некорректный формат';
              } else {
                errorText = null;
              }
            });
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: colors.hintColor.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isValid ? colors.iconColor : colors.errorColor,
            ),
            suffixIcon: showVisibilityToggle
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: isValid ? colors.iconColor : colors.errorColor,
                    ),
                    onPressed: onVisibilityToggle,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? colors.primaryColor : colors.errorColor,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.errorColor,
              ),
            ),
            filled: true,
            fillColor: isValid
                ? adjustedInputBackground // Используем осветленный фон
                : colors.errorColor.withOpacity(0.15),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
          cursorColor: isValid ? colors.primaryColor : colors.errorColor,
          style: TextStyle(
            color: colors.textColor,
            fontSize: 16,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                helperText,
                style: TextStyle(
                  color: isValid ? colors.hintColor : colors.errorColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _lightenColor(Color color, double amount) {
    final hslColor = HSLColor.fromColor(color);
    final lightness = (hslColor.lightness + amount).clamp(0.0, 1.0);
    return hslColor.withLightness(lightness).toColor();
  }
}
