// mini_apps/criss_cross/presentation/widgets/board_widget.dart

import 'package:flutter/material.dart';
import 'package:shsh_social/core/utils/AppColors.dart';
import 'package:shsh_social/features/mini_apps/presentation/widgets/criss_cross/presentation/widgets/cell_widget.dart';
import 'package:shsh_social/features/settings/data/services/theme_manager.dart';

class BoardWidget extends StatelessWidget {
  final List<List<String>> board;
  final Function(int row, int col) onCellTap;

  const BoardWidget({
    required this.board,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = screenWidth / (board.length + 2);
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Column(
      children: List.generate(board.length, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(board[row].length, (col) {
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: CellWidget(
                value: board[row][col],
                onTap: () => onCellTap(row, col),
                colors: colors,
              ),
            );
          }),
        );
      }),
    );
  }
}
