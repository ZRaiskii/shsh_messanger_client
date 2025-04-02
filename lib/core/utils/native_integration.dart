import 'package:flutter/services.dart';

class NativeIntegration {
  static const MethodChannel _channel = MethodChannel('com.example/native');

  static Future<void> showNotification(String message) async {
    await _channel.invokeMethod('showNotification', {'message': message});
  }
}
