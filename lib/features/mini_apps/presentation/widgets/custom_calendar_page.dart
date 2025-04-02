import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shsh_social/core/utils/AppColors.dart'; // Импортируем AppColors
import '../../../settings/data/services/theme_manager.dart';

import '../../../../core/data_base_helper.dart'; // Импортируем theme_manager

class CustomCalendarPage extends StatefulWidget {
  @override
  _CustomCalendarPageState createState() => _CustomCalendarPageState();
}

class _CustomCalendarPageState extends State<CustomCalendarPage> {
  DateTime _currentDate = DateTime.now(); // Текущая выбранная дата
  DateTime _focusedDate = DateTime.now(); // Текущий отображаемый месяц
  Map<DateTime, List<Event>> _events = {}; // События по датам

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await DatabaseHelper().getAllEvents();
    setState(() {
      _events.clear();
      for (final event in events) {
        final date = DateTime.parse(event.date);
        _events[date] ??= [];
        _events[date]!.add(event);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Свайп вправо
            _changeMonth(-1);
          } else if (details.primaryVelocity! < 0) {
            // Свайп влево
            _changeMonth(1);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                      color: colors.iconColor,
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                      color: colors.iconColor,
                    ),
                  ],
                ),
                _buildCalendar(colors),
                if (_events[_currentDate] != null &&
                    _events[_currentDate]!.isNotEmpty)
                  Card(
                    margin: EdgeInsets.all(8),
                    color: colors.cardColor,
                    elevation: 4,
                    child: Container(
                      height: 350,
                      child: _buildEventList(colors),
                    ),
                  ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        backgroundColor: colors.buttonColor,
        child: Icon(
          Icons.add,
          color: colors.buttonTextColor,
        ),
      ),
    );
  }

  // Построение календаря
  Widget _buildCalendar(AppColors colors) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final startingOffset =
        firstDayOfMonth.weekday - 1; // Смещение для первого дня месяца

    return GridView.builder(
      shrinkWrap: true, // Чтобы календарь не занимал всё пространство
      physics: NeverScrollableScrollPhysics(), // Отключаем скролл календаря
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7 дней в неделе
      ),
      itemCount: daysInMonth + startingOffset,
      itemBuilder: (context, index) {
        if (index < startingOffset) {
          return Container(); // Пустые ячейки до первого дня месяца
        }

        final day = index - startingOffset + 1;
        final currentDay = DateTime(_focusedDate.year, _focusedDate.month, day);

        return GestureDetector(
          onTap: () => _selectDate(currentDay),
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSameDay(currentDay, _currentDate)
                  ? colors.primaryColor.withOpacity(0.3)
                  : colors.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowColor,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 18,
                  color: isSameDay(currentDay, DateTime.now())
                      ? colors.primaryColor
                      : colors.textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Отображение списка событий
  Widget _buildEventList(AppColors colors) {
    return ListView.separated(
      shrinkWrap: true, // Чтобы ListView не занимал всё пространство
      itemCount: _events[_currentDate]?.length ?? 0,
      separatorBuilder: (context, index) => Divider(
        color: colors.dividerColor,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final event = _events[_currentDate]![index];
        return ListTile(
          title: Text(
            event.title,
            style: TextStyle(color: colors.textColor),
          ),
          subtitle: Text(
            '${event.description}\nВремя: ${_formatTimeString(event.time)}',
            style: TextStyle(color: colors.hintColor),
          ),
        );
      },
    );
  }

  String _formatTimeString(String timeString) {
    final parts = timeString.split(':');

    if (parts.length != 2) {
      throw FormatException('Invalid time format: $timeString');
    }

    final hours = parts[0].padLeft(2, '0');
    final minutes = parts[1].padLeft(2, '0');

    return '$hours:$minutes';
  }

  void _addEvent() async {
    final event = await showDialog<Event>(
      context: context,
      builder: (context) {
        String title = '';
        String description = '';
        TimeOfDay selectedTime = TimeOfDay.now();

        final colors =
            isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colors.backgroundColor,
              title: Text(
                'Добавить событие',
                style: TextStyle(color: colors.textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => title = value,
                      decoration: InputDecoration(
                        hintText: 'Название события',
                        hintStyle: TextStyle(color: colors.hintColor),
                      ),
                      style: TextStyle(color: colors.textColor),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => description = value,
                      decoration: InputDecoration(
                        hintText: 'Описание события',
                        hintStyle: TextStyle(color: colors.hintColor),
                      ),
                      style: TextStyle(color: colors.textColor),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        'Время: ${selectedTime.format(context)}',
                        style: TextStyle(color: colors.textColor),
                      ),
                      trailing:
                          Icon(Icons.access_time, color: colors.iconColor),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      Event(
                        date: _currentDate
                            .toIso8601String()
                            .split('T')[0], // Дата в формате "YYYY-MM-DD"
                        title: title,
                        description: description,
                        time:
                            '${selectedTime.hour}:${selectedTime.minute}', // Время в формате "HH:MM"
                      ),
                    );
                  },
                  child: Text(
                    'Добавить',
                    style: TextStyle(color: colors.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: colors.errorColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (event != null) {
      // Сохраняем событие в базу данных
      await DatabaseHelper().insertEvent(event);

      // Обновляем состояние
      setState(() {
        _events[_currentDate] ??= [];
        _events[_currentDate]!.add(event);
      });
    }
  }

  // Выбор даты
  void _selectDate(DateTime date) {
    setState(() {
      _currentDate = DateTime(date.year, date.month, date.day);
      _loadEvents();
    });
  }

  // Переключение месяцев
  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
    });
  }

  // Получение названия месяца
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Январь';
      case 2:
        return 'Февраль';
      case 3:
        return 'Март';
      case 4:
        return 'Апрель';
      case 5:
        return 'Май';
      case 6:
        return 'Июнь';
      case 7:
        return 'Июль';
      case 8:
        return 'Август';
      case 9:
        return 'Сентябрь';
      case 10:
        return 'Октябрь';
      case 11:
        return 'Ноябрь';
      case 12:
        return 'Декабрь';
      default:
        return '';
    }
  }

  // Проверка, совпадают ли две даты
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class Event {
  int? id; // Идентификатор события (автоинкремент)
  final String date; // Дата события
  final String title; // Название события
  final String description; // Описание события
  final String time; // Время события

  Event({
    this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.time,
  });

  /// Преобразует объект Event в Map (для сохранения в базу данных)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'description': description,
      'time': time,
    };
  }

  /// Создает объект Event из Map (для загрузки из базы данных)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      date: json['date'],
      title: json['title'],
      description: json['description'],
      time: json['time'],
    );
  }
}
