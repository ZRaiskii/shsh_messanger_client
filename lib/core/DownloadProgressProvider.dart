import 'package:flutter/material.dart';

class DownloadProgressProvider with ChangeNotifier {
  int _progress = 0;

  int get progress => _progress;

  void updateProgress(int progress) {
    _progress = progress;
    notifyListeners();
  }

  void resetProgress() {
    _progress = 0;
    notifyListeners();
  }
}
