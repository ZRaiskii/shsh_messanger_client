import 'package:flutter/material.dart';
import '../../../../../../../core/utils/AppColors.dart';
import '../../../../../../settings/data/services/theme_manager.dart';
import '../../data/wordle_manager.dart';
import '../widgets/statistic_card_widget.dart';
import 'game_page.dart';

class WordleHomePage extends StatefulWidget {
  final WordleManager wordleManager;

  WordleHomePage({required this.wordleManager});

  @override
  _WordleHomePageState createState() => _WordleHomePageState();
}

class _WordleHomePageState extends State<WordleHomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await widget.wordleManager.loadStats();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatisticsCard(wordleManager: widget.wordleManager),
                    SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: 'Начать новую игру',
                              onPressed: () async {
                                widget.wordleManager.startNewGame();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GamePage(
                                        wordleManager: widget.wordleManager),
                                  ),
                                );
                                if (result != null) {
                                  _showMessageDialog(result);
                                }
                                setState(() {});
                              },
                            ),
                            SizedBox(height: 10),
                            _buildActionButton(
                              icon: Icons.today_rounded,
                              label: 'Угадать слово дня',
                              onPressed: () {
                                // Логика для угадывания слова дня
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Результат игры'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
