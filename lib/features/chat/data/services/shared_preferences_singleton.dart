import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesSingleton {
  static final SharedPreferencesSingleton _instance =
      SharedPreferencesSingleton._internal();
  static late ValueNotifier<SharedPreferences> _sharedPreferencesNotifier;

  factory SharedPreferencesSingleton() {
    return _instance;
  }

  SharedPreferencesSingleton._internal();

  static Future<void> init() async {
    _sharedPreferencesNotifier =
        ValueNotifier<SharedPreferences>(await SharedPreferences.getInstance());
  }

  static ValueListenable<SharedPreferences> getInstance() {
    return _sharedPreferencesNotifier;
  }
}
