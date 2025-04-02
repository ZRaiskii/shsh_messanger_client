// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:shsh_social/features/auth/presentation/pages/auth_page.dart';
import 'package:shsh_social/features/main/presentation/pages/main_page.dart';
import 'package:shsh_social/features/profile/presentation/pages/profile_page.dart';
import 'package:shsh_social/features/settings/presentation/pages/settings_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => AuthPage(),
  '/main': (context) => MainPage(),
  '/profile': (context) => ProfilePage(userId: 'example_user_id'),
  '/settings': (context) => SettingsPage(),
};
