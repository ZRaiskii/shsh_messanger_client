// mini_apps/criss_cross/data/bot_logic.dart

class BotLogic {
  static int? findBestMove(List<List<String>> board, String botSymbol) {
    final size = board.length;
    final opponentSymbol = botSymbol == "X" ? "O" : "X";

    // Проверка на победный ход для бота
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j].isEmpty) {
          board[i][j] = botSymbol;
          if (_checkWin(board, botSymbol, i, j, size)) {
            board[i][j] = "";
            return i * size + j;
          }
          board[i][j] = "";
        }
      }
    }

    // Проверка на блокирующий ход противника
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j].isEmpty) {
          board[i][j] = opponentSymbol;
          if (_checkWin(board, opponentSymbol, i, j, size)) {
            board[i][j] = "";
            return i * size + j;
          }
          board[i][j] = "";
        }
      }
    }

    // Случайный ход
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j].isEmpty) {
          return i * size + j;
        }
      }
    }

    return null;
  }

  static bool _checkWin(
      List<List<String>> board, String symbol, int row, int col, int size) {
    // Проверка строки
    if (board[row].every((cell) => cell == symbol)) return true;

    // Проверка столбца
    if (board.every((r) => r[col] == symbol)) return true;

    // Проверка диагоналей
    if (row == col &&
        board.asMap().entries.every((e) => board[e.key][e.key] == symbol))
      return true;
    if (row + col == size - 1 &&
        board
            .asMap()
            .entries
            .every((e) => board[e.key][size - 1 - e.key] == symbol))
      return true;

    return false;
  }
}
