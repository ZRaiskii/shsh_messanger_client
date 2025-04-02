// lib/core/widgets/new_year/new_year_decoration.dart
import 'package:flutter/material.dart';

class NewYearDecoration extends StatelessWidget {
  final String assetImage;

  const NewYearDecoration({super.key, required this.assetImage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Image.asset(
          assetImage,
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}
