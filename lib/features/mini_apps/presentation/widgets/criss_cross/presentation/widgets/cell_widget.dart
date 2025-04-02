// mini_apps/criss_cross/presentation/widgets/cell_widget.dart

import 'package:flutter/material.dart';
import 'package:shsh_social/core/utils/AppColors.dart';

class CellWidget extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final AppColors colors;

  const CellWidget({
    required this.value,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: value == "X" ? colors.primaryColor : colors.secondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
