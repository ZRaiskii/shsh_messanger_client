// mini_apps/criss_cross/presentation/criss_cross_screen.dart

import 'package:flutter/material.dart';
import 'package:shsh_social/core/utils/AppColors.dart';
import 'package:shsh_social/features/settings/data/services/theme_manager.dart';
import '../data/game_logic.dart';
import '../data/bot_logic.dart';
import 'widgets/board_widget.dart';

class CrissCrossScreen extends StatefulWidget {
  @override
  _CrissCrossScreenState createState() => _CrissCrossScreenState();
}

class _CrissCrossScreenState extends State<CrissCrossScreen> {
  late GameLogic _gameLogic;
  int _selectedSize = 3;
  bool _isBotMode = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _gameLogic = GameLogic(size: _selectedSize);
    });
  }

  void _makeBotMove() {
    if (!_isBotMode || _gameLogic.isGameOver || _gameLogic.currentPlayer != "O")
      return;

    final move = BotLogic.findBestMove(_gameLogic.board, "O");
    if (move != null) {
      final row = move ~/ _selectedSize;
      final col = move % _selectedSize;
      _gameLogic.makeMove(row, col);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Карточка с выбором режима игры и размера поля
              Card(
                color: colors.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButton<int>(
                        value: _selectedSize,
                        onChanged: (value) {
                          setState(() {
                            _selectedSize = value!;
                            _resetGame();
                          });
                        },
                        items: [3, 5, 9]
                            .map((size) => DropdownMenuItem(
                                  value: size,
                                  child: Text(
                                    '$size x $size',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      SwitchListTile(
                        title: Text(
                          "Играть с ботом",
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.textColor,
                          ),
                        ),
                        value: _isBotMode,
                        onChanged: (value) {
                          setState(() {
                            _isBotMode = value;
                            _resetGame();
                          });
                        },
                        activeColor: colors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Текст состояния игры
              Text(
                _gameLogic.isGameOver
                    ? _gameLogic.board
                            .any((row) => row.any((cell) => cell.isNotEmpty))
                        ? "Победил ${_gameLogic.currentPlayer}!"
                        : "Ничья!"
                    : "Ходит ${_gameLogic.currentPlayer}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              SizedBox(height: 20),
              // Игровое поле
              Expanded(
                child: BoardWidget(
                  board: _gameLogic.board,
                  onCellTap: (row, col) {
                    if (_gameLogic.makeMove(row, col)) {
                      setState(() {});
                      Future.delayed(Duration(milliseconds: 500), _makeBotMove);
                    }
                  },
                ),
              ),
              SizedBox(height: 20),
              // Кнопка "Начать заново"
              ElevatedButton(
                onPressed: _resetGame,
                style: ElevatedButton.styleFrom(
                  foregroundColor: colors.buttonTextColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: colors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Начать заново",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
