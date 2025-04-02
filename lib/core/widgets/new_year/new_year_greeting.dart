// lib/core/widgets/new_year/new_year_greeting.dart
import 'package:flutter/material.dart';

class NewYearGreeting extends StatelessWidget {
  final String message;

  const NewYearGreeting({super.key, this.message = 'С Новым 2025 годом!'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
