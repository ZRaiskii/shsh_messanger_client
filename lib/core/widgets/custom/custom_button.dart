// lib/core/widgets/custom/custom_button.dart
import 'package:flutter/material.dart';
import 'package:shsh_social/core/utils/AppColors.dart';
import '../base/base_button.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final AppColors colors;

  const CustomButton({
    required this.onPressed,
    required this.text,
    required this.colors,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 43, 146, 236),
        foregroundColor: colors.buttonTextColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
