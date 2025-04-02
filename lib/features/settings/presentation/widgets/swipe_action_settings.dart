import 'package:flutter/cupertino.dart';

import '../../../../core/utils/AppColors.dart';

class SwipeActionSetting extends StatefulWidget {
  final AppColors colors;

  SwipeActionSetting({required this.colors});

  @override
  _SwipeActionSettingState createState() => _SwipeActionSettingState();
}

class _SwipeActionSettingState extends State<SwipeActionSetting> {
  String _swipeAction = 'Нет';
  final List<String> _actions = ['Нет', 'Удалить', 'Архивировать', 'Прочитать'];

  void _saveSettings() {
    // Сохранение настроек
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Действие на свайп влево',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.colors.textColor,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: CupertinoPicker(
            itemExtent: 40,
            onSelectedItemChanged: (int index) {
              setState(() {
                _swipeAction = _actions[index];
                _saveSettings();
              });
            },
            children: _actions.map((String action) {
              return Center(
                child: Text(
                  action,
                  style: TextStyle(color: widget.colors.textColor),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
