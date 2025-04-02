// mini_apps/criss_cross/data/game_logic.dart

class GameLogic {
  late List<List<String>> _board;
  String currentPlayer = "X";
  bool isGameOver = false;
  final int size;

  GameLogic({this.size = 3}) {
    _board = List.generate(size, (_) => List.filled(size, ""));
  }

  // Получить текущее состояние доски
  List<List<String>> get board => List.unmodifiable(_board);

  // Сделать ход
  bool makeMove(int row, int col) {
    if (_board[row][col].isNotEmpty || isGameOver) return false;

    _board[row][col] = currentPlayer;
    if (_checkWin(row, col)) {
      isGameOver = true;
      return true;
    }

    if (_isDraw()) {
      isGameOver = true;
      return true;
    }

    currentPlayer = currentPlayer == "X" ? "O" : "X";
    return true;
  }

  // Проверка на победу
  bool _checkWin(int row, int col) {
    final symbol = _board[row][col];

    // Проверка строки
    if (_board[row].every((cell) => cell == symbol)) return true;

    // Проверка столбца
    if (_board.every((r) => r[col] == symbol)) return true;

    // Проверка диагоналей
    if (row == col &&
        _board.asMap().entries.every((e) => _board[e.key][e.key] == symbol))
      return true;
    if (row + col == size - 1 &&
        _board
            .asMap()
            .entries
            .every((e) => _board[e.key][size - 1 - e.key] == symbol))
      return true;

    return false;
  }

  // Проверка на ничью
  bool _isDraw() => _board.every((row) => row.every((cell) => cell.isNotEmpty));

  // Сброс игры
  void reset() {
    for (var row in _board) {
      row.fillRange(0, row.length, "");
    }
    currentPlayer = "X";
    isGameOver = false;
  }
}
