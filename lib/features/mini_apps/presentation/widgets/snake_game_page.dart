import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math';

import '../../../main/presentation/pages/main_page.dart';

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  _SnakeGamePageState createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  late SnakeGame _game;

  @override
  void initState() {
    super.initState();
    _game = SnakeGame();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainPage()),
        );
        return false;
      },
      child: Scaffold(
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0 && _game.direction != 1) {
              setState(() {
                _game.direction = 3; // down
              });
            } else if (details.delta.dy < 0 && _game.direction != 3) {
              setState(() {
                _game.direction = 1; // up
              });
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0 && _game.direction != 2) {
              setState(() {
                _game.direction = 0; // right
              });
            } else if (details.delta.dx < 0 && _game.direction != 0) {
              setState(() {
                _game.direction = 2; // left
              });
            }
          },
          child: GameWidget(
            game: _game,
          ),
        ),
      ),
    );
  }
}

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SnakeGamePage()),
            );
          },
          child: const Text('Start Game'),
        ),
      ),
    );
  }
}

class SnakeGame extends FlameGame {
  late RectangleComponent snakeHead;
  late List<RectangleComponent> snakeBody;
  RectangleComponent? food;
  double direction = 0; // 0: right, 1: up, 2: left, 3: down
  late double gridSize;
  late int rows;
  late int cols;
  late double moveInterval;
  double timeSinceLastMove = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    gridSize = 40; // Increase grid size to 40
    rows = (size.y / gridSize).toInt();
    cols = (size.x / gridSize).toInt();
    moveInterval = 0.5; // Move every 0.5 seconds

    snakeHead = RectangleComponent(
      size: Vector2(gridSize, gridSize),
      position: Vector2(cols ~/ 2 * gridSize, rows ~/ 2 * gridSize),
      paint: Paint()..color = Colors.green,
    );
    add(snakeHead);

    snakeBody = [];

    spawnFood();
    drawGrid();
  }

  void drawGrid() {
    for (int i = 0; i <= cols; i++) {
      add(RectangleComponent(
        size: Vector2(1, size.y),
        position: Vector2(i * gridSize, 0),
        paint: Paint()..color = Colors.grey,
      ));
    }
    for (int i = 0; i <= rows; i++) {
      add(RectangleComponent(
        size: Vector2(size.x, 1),
        position: Vector2(0, i * gridSize),
        paint: Paint()..color = Colors.grey,
      ));
    }
  }

  void spawnFood() {
    // Remove the old food component if it exists
    if (food != null) {
      remove(food!);
    }

    food = RectangleComponent(
      size: Vector2(gridSize, gridSize),
      position: Vector2(
        (Random().nextInt(cols) * gridSize).toDouble(),
        (Random().nextInt(rows) * gridSize).toDouble(),
      ),
      paint: Paint()..color = Colors.red,
    );
    add(food!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastMove += dt;

    if (timeSinceLastMove >= moveInterval) {
      timeSinceLastMove = 0;
      moveSnake();
    }
  }

  void moveSnake() {
    Vector2 newPosition = snakeHead.position.clone();

    switch (direction) {
      case 0:
        newPosition.x += gridSize;
        break;
      case 1:
        newPosition.y -= gridSize;
        break;
      case 2:
        newPosition.x -= gridSize;
        break;
      case 3:
        newPosition.y += gridSize;
        break;
    }

    // Check for collision with walls
    if (newPosition.x < 0 ||
        newPosition.x >= size.x ||
        newPosition.y < 0 ||
        newPosition.y >= size.y) {
      pauseEngine();
      showGameOverDialog();
      return;
    }

    // Check for collision with food
    if (food != null && newPosition.distanceTo(food!.position) < gridSize) {
      spawnFood();
      // Add new body part
      snakeBody.add(RectangleComponent(
        size: Vector2(gridSize, gridSize),
        position:
            snakeBody.isNotEmpty ? snakeBody.last.position : snakeHead.position,
        paint: Paint()..color = Colors.green,
      ));
      add(snakeBody.last);
    } else {
      // Move snake body
      for (int i = snakeBody.length - 1; i > 0; i--) {
        snakeBody[i].position = snakeBody[i - 1].position;
      }
      if (snakeBody.isNotEmpty) {
        snakeBody[0].position = snakeHead.position;
      }
    }

    snakeHead.position = newPosition;
  }

  void showGameOverDialog() {
    // Show a game over dialog
    showDialog(
      context: buildContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: const Text('You hit the wall!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    // Reset the game state
    removeAll(children);
    onLoad();
    resumeEngine();
  }
}
