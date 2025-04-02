// lib/core/widgets/custom/custom_loading_indicator.dart
import 'package:flutter/material.dart';

import '../base/base_loading_indicator.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const CustomLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return BaseLoadingIndicator(
      size: size,
      color: color,
    );
  }
}
