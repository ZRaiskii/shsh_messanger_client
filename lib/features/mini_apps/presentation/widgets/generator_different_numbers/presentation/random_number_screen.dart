import 'package:flutter/material.dart';
import '../data/random_number_service.dart';
import 'widgets/generate_button.dart';
import 'widgets/number_display.dart';
import '../../../../../settings/data/services/theme_manager.dart';

import '../../../../../../core/utils/AppColors.dart';

class RandomNumberScreen extends StatefulWidget {
  const RandomNumberScreen({super.key});

  @override
  State<RandomNumberScreen> createState() => _RandomNumberScreenState();
}

class _RandomNumberScreenState extends State<RandomNumberScreen> {
  final RandomNumberService _service = RandomNumberService();
  int? _currentNumber;

  final TextEditingController _minController = TextEditingController(text: '1');
  final TextEditingController _maxController =
      TextEditingController(text: '100');

  void _generateRandomNumber() {
    final minText = _minController.text;
    final maxText = _maxController.text;

    if (minText.isEmpty || maxText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните оба поля')),
      );
      return;
    }

    final min = int.tryParse(minText);
    final max = int.tryParse(maxText);

    if (min == null || max == null || min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Некорректные значения минимума и максимума')),
      );
      return;
    }

    setState(() {
      _currentNumber = _service.generateRandomNumber(min: min, max: max);
    });
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      body: Container(
        color: colors.backgroundColor,
        padding: const EdgeInsets.all(2),
        child: Card(
          color: isWhiteNotifier.value
              ? Colors.white
              : Color.lerp(colors.appBarColor, Colors.black, 0.4),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NumberDisplay(number: _currentNumber),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minController,
                      maxLength: 9,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Минимум',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: colors.cardColor,
                      ),
                      style: TextStyle(color: colors.textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _maxController,
                      maxLength: 9,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Максимум',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: colors.cardColor,
                      ),
                      style: TextStyle(color: colors.textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GenerateButton(onPressed: _generateRandomNumber),
            ],
          ),
        ),
      ),
    );
  }
}
