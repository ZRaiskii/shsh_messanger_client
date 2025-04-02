// lib/core/widgets/base/base_loading_indicator.dart
import 'package:flutter/material.dart';

class BaseLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const BaseLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 4.0,
      ),
    );
  }
}
