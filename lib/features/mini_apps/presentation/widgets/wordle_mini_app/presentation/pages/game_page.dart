import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../core/utils/AppColors.dart';
import '../../../../../../settings/data/services/theme_manager.dart';
import '../../data/wordle_manager.dart';
import '../widgets/custom_keyboard_widget.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../core/utils/AppColors.dart';
import '../../../../../../settings/data/services/theme_manager.dart';
import '../../data/wordle_manager.dart';
import '../widgets/custom_keyboard_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GamePage extends StatefulWidget {
  final WordleManager wordleManager;
  GamePage({required this.wordleManager});
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final ValueNotifier<List<String>> guessesNotifier;
  late final ValueNotifier<List<List<Color>>> colorsNotifier;
  late final ValueNotifier<Map<String, Color>> letterStatusNotifier;

  bool _isEnterKeyPressed = false;
  Timer? _enterKeyTimeout;

  final Map<String, String> _enToRu = {
    'Q': 'Й',
    'W': 'Ц',
    'E': 'У',
    'R': 'К',
    'T': 'Е',
    'Y': 'Н',
    'U': 'Г',
    'I': 'Ш',
    'O': 'Щ',
    'P': 'З',
    '[': 'Х',
    ']': 'Ъ',
    'A': 'Ф',
    'S': 'Ы',
    'D': 'В',
    'F': 'А',
    'G': 'П',
    'H': 'Р',
    'J': 'О',
    'K': 'Л',
    'L': 'Д',
    ';': 'Ж',
    '\'': 'Э',
    'Z': 'Я',
    'X': 'Ч',
    'C': 'С',
    'V': 'М',
    'B': 'И',
    'N': 'Т',
    'M': 'Ь',
    ',': 'Б',
    '.': 'Ю',
    '/': '.',
    ' ': ' '
  };

  bool _isRussianCharacter(String character) {
    final russianRange = RegExp(r'^[А-ЯЁ]$');
    return russianRange.hasMatch(character);
  }

  @override
  void initState() {
    super.initState();
    guessesNotifier = widget.wordleManager.guessesNotifier;
    colorsNotifier = widget.wordleManager.colorsNotifier;
    letterStatusNotifier = ValueNotifier({});

    colorsNotifier.addListener(_updateLetterStatus);
    if (Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    }
  }

  @override
  void dispose() {
    _enterKeyTimeout?.cancel();
    super.dispose();
  }

  void _updateLetterStatus() {
    final guesses = guessesNotifier.value;
    final colorsList = colorsNotifier.value;
    final letterStatus = <String, Color>{};

    if (colorsList.isNotEmpty && colorsList.length == guesses.length) {
      for (int i = 0; i < guesses.length; i++) {
        final guess = guesses[i];
        final colors = colorsList[i];

        for (int j = 0; j < guess.length; j++) {
          final letter = guess[j];
          final color = colors[j];
          letterStatus[letter] = color;
        }
      }
    }

    letterStatusNotifier.value = letterStatus;
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    final focusNode = FocusNode();

    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent && !event.repeat) {
          // Обработка Esc
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return;
          }

          // Обработка специальных клавиш
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _handleKeyPress('Backspace');
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleKeyPress('Enter');
            return;
          }

          // Обработка буквенных клавиш
          if (Platform.isWindows) {
            final keyLabel = event.logicalKey.keyLabel.toUpperCase();
            final character = event.character?.toUpperCase();

            debugPrint('Key pressed: $keyLabel, Character: $character');

            if (character != null && _isRussianCharacter(character)) {
              _handleKeyPress(character);
            } else {
              final ruChar = _enToRu[keyLabel];
              if (ruChar != null) {
                _handleKeyPress(ruChar);
              }
            }
          } else {
            final character = event.character?.toUpperCase();
            if (character != null && character.isNotEmpty) {
              _handleKeyPress(character);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        body: Focus(
          autofocus: true,
          child: Column(
            children: [
              Expanded(child: _buildGrid()),
              ValueListenableBuilder<Map<String, Color>>(
                valueListenable: letterStatusNotifier,
                builder: (context, letterStatus, _) {
                  return CustomKeyboard(
                    onKeyPressed: _handleKeyPress,
                    letterStatus: letterStatus,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    final wordLength = widget.wordleManager.currentWord.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        if (Platform.isWindows) {
          var aspectRatio = 9 / 13;
          if (wordLength > 4) {
            aspectRatio = 9 / 8;
          }

          final gridWidth = screenWidth;

          final gridHeight = gridWidth / aspectRatio;

          final adjustedHeight =
              gridHeight > screenHeight ? screenHeight : gridHeight;
          final adjustedWidth = adjustedHeight * aspectRatio;

          final crossAxisCount = wordLength;

          return Center(
            child: Container(
              width: adjustedWidth,
              height: adjustedHeight,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: guessesNotifier,
                builder: (context, guesses, _) {
                  return ValueListenableBuilder<List<List<Color>>>(
                    valueListenable: colorsNotifier,
                    builder: (context, colorsList, _) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: 5 * crossAxisCount,
                        itemBuilder: (context, index) {
                          final row = index ~/ crossAxisCount;
                          final col = index % crossAxisCount;
                          final guess =
                              guesses.length > row ? guesses[row] : '';
                          final letter = col < guess.length ? guess[col] : '';
                          final color = colorsList.length > row &&
                                  col < colorsList[row].length
                              ? colorsList[row][col]
                              : colors.cardColor;

                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(color: colors.borderColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                letter.toUpperCase(),
                                style: TextStyle(
                                  fontSize: adjustedWidth > 400 ? 48 : 16,
                                  color: colors.textColor,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        } else {
          // Для телефонов используем старый вариант во всю ширину
          final crossAxisCount = wordLength;

          return ValueListenableBuilder<List<String>>(
            valueListenable: guessesNotifier,
            builder: (context, guesses, _) {
              return ValueListenableBuilder<List<List<Color>>>(
                valueListenable: colorsNotifier,
                builder: (context, colorsList, _) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.0,
                    ),
                    itemCount:
                        5 * crossAxisCount, // 5 строк по crossAxisCount ячеек
                    itemBuilder: (context, index) {
                      final row = index ~/ crossAxisCount;
                      final col = index % crossAxisCount;
                      final guess = guesses.length > row ? guesses[row] : '';
                      final letter = col < guess.length ? guess[col] : '';
                      final color = colorsList.length > row &&
                              col < colorsList[row].length
                          ? colorsList[row][col]
                          : colors.cardColor;

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: colors.borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            letter.toUpperCase(),
                            style: TextStyle(
                              fontSize: screenWidth > 800 ? 24 : 18,
                              color: colors.textColor,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  void _handleKeyPress(String key) async {
    List<String> currentGuesses = List.from(guessesNotifier.value);
    if (currentGuesses.isEmpty) {
      currentGuesses = [''];
    }
    String currentGuess = currentGuesses.last;

    if (key == 'Enter') {
      // Проверяем, не был ли Enter уже нажат
      if (_isEnterKeyPressed) {
        print('Повторное нажатие Enter заблокировано.');
        return;
      }

      // Устанавливаем флаг и запускаем таймер
      _isEnterKeyPressed = true;
      _enterKeyTimeout = Timer(const Duration(seconds: 2), () {
        _isEnterKeyPressed = false; // Сбрасываем флаг после таймаута
      });

      if (currentGuess.length == widget.wordleManager.currentWord.length) {
        // Проверяем существование слова через Wikidata API
        bool exists = await checkWordExists(currentGuess.toLowerCase());
        if (!exists) {
          print('Слово "$currentGuess" не существует!');
          return; // Прерываем выполнение, если слово не существует
        }

        // Если слово существует, продолжаем логику игры
        widget.wordleManager.makeGuess(currentGuess);
        currentGuesses.add('');
        guessesNotifier.value = currentGuesses;

        if (currentGuess.toLowerCase() ==
                widget.wordleManager.currentWord.toLowerCase() ||
            widget.wordleManager.attempts == 5) {
          _endGame(currentGuess.toLowerCase(),
              widget.wordleManager.currentWord.toLowerCase());
        }
      }
    } else if (key == 'Backspace') {
      if (currentGuess.isNotEmpty) {
        currentGuess = currentGuess.substring(0, currentGuess.length - 1);
        currentGuesses[currentGuesses.length - 1] = currentGuess;
        guessesNotifier.value = List.from(currentGuesses);
      }
    } else {
      if (currentGuess.length < widget.wordleManager.currentWord.length) {
        currentGuess += key;
        currentGuesses[currentGuesses.length - 1] = currentGuess;
        guessesNotifier.value = List.from(currentGuesses);
      }
    }
  }

  void _endGame(String currentGuess, String currentWord) async {
    final prefs = await SharedPreferences.getInstance();
    if (currentGuess == currentWord) {
      widget.wordleManager.totalWinsNotifier.value += 1;
      widget.wordleManager.streakNotifier.value += 1;
    } else {
      widget.wordleManager.streakNotifier.value = 0;
    }
    await prefs.setInt('totalGames', widget.wordleManager.totalGames);
    await prefs.setInt('totalWins', widget.wordleManager.totalWins);
    await prefs.setInt('streak', widget.wordleManager.streak);

    final message = currentGuess != currentWord
        ? 'Вы проиграли! Попробуйте ещё раз.\n Правильное слово: $currentWord'
        : 'Поздравляем! Вы выиграли!';

    Navigator.pop(context, message);
  }

  Future<bool> checkWordExists(String word) async {
    final url = Uri.parse('https://www.wikidata.org/w/api.php');
    final params = {
      'action': 'wbsearchentities',
      'search': word,
      'format': 'json',
      'language': 'ru',
      'uselang': 'ru',
      'origin': '*',
    };

    try {
      final response = await http.get(url.replace(queryParameters: params));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['search'] != null && data['search'].isNotEmpty) {
          print(
              'Слово "$word" найдено. Описание: ${data['search'][0]['description']}');
          if (data['search'][0]['description'] != null) {
            return true;
          }
          return false;
        } else {
          print('Слово "$word" не найдено.');
          return false;
        }
      } else {
        print('Ошибка HTTP: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('Произошла ошибка при запросе к Wikidata: $error');
      return false;
    }
  }
}
