import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data_base_helper.dart';

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({Key? key}) : super(key: key);

  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  int _steps = 0;
  int _goal = 5500; // Default goal
  List<int> _weeklySteps = List.filled(7, 0);
  int _monthlySteps = 0;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermissions();
    initPlatformState();
    loadWeeklySteps();
    loadMonthlySteps();
    loadGoal();
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.activityRecognition,
      Permission.location,
    ].request();

    final info = statuses[Permission.activityRecognition].toString();
    print(info);
  }

  void initPlatformState() {
    _stepCountStream = Pedometer.stepCountStream;
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

    _stepCountStream.listen((StepCount event) {
      setState(() {
        _steps = event.steps;
        updateWeeklySteps(event.steps);
      });
    }).onError((error) {
      debugPrint(error.toString());
    });

    _pedestrianStatusStream.listen((PedestrianStatus event) {
      setState(() {});
    }).onError((error) {
      debugPrint(error.toString());
    });
  }

  void updateWeeklySteps(int steps) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _databaseHelper.insertStepCount(today, steps);
    loadWeeklySteps();
    loadMonthlySteps();
  }

  void loadWeeklySteps() async {
    List<Map<String, dynamic>> weeklyData =
        await _databaseHelper.getWeeklyStepCounts();
    _weeklySteps = List.filled(7, 0); // Ensure the list always has 7 elements
    for (var data in weeklyData) {
      int index = DateTime.parse(data['date'] as String).weekday - 1;
      if (index >= 0 && index < 7) {
        _weeklySteps[index] = data['steps'] as int;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void loadMonthlySteps() async {
    int totalSteps = 0;
    List<Map<String, dynamic>> monthlyData =
        await _databaseHelper.getMonthlyStepCounts();
    for (var data in monthlyData) {
      totalSteps += data['steps'] as int;
    }
    setState(() {
      _monthlySteps = totalSteps;
    });
  }

  void updateGoal(int newGoal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal', newGoal);
    setState(() {
      _goal = newGoal;
    });
  }

  void loadGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedGoal = prefs.getInt('goal');
    if (savedGoal != null) {
      setState(() {
        _goal = savedGoal;
      });
    }
  }

  void _showGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Изменить цель'),
          content: TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Новая цель',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: () {
                int newGoal = int.tryParse(_goalController.text) ?? _goal;
                updateGoal(newGoal);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<ChartData> getChartData() {
    return [
      ChartData('Пн', _weeklySteps[0]),
      ChartData('Вт', _weeklySteps[1]),
      ChartData('Ср', _weeklySteps[2]),
      ChartData('Чт', _weeklySteps[3]),
      ChartData('Пт', _weeklySteps[4]),
      ChartData('Сб', _weeklySteps[5]),
      ChartData('Вс', _weeklySteps[6]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Секция шагов за день
              GestureDetector(
                onTap: () => _showGoalDialog(context),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: colors.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.today, color: colors.iconColor),
                            SizedBox(width: 8),
                            Text(
                              'Сегодняшние шаги',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colors.textColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$_steps',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: colors.textColor,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag, color: colors.iconColor),
                            SizedBox(width: 8),
                            Text(
                              'Цель: $_goal',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.textColor,
                              ),
                            ),
                          ],
                        ),
                        LinearProgressIndicator(
                          value: _steps / _goal,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // График шагов за неделю
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: colors.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: colors.iconColor),
                          SizedBox(width: 8),
                          Text(
                            'Шаги за неделю:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 10000,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        getChartData()[value.toInt()].x,
                                        style: TextStyle(
                                          color: colors.textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 38,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: colors.textColor,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                  interval: 1000,
                                ),
                              ),
                              rightTitles: AxisTitles(),
                              topTitles: AxisTitles(),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: colors.iconColor.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            barGroups: getChartData().asMap().entries.map((e) {
                              final data = e.value;
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.y.toDouble(),
                                    color: Colors.blue,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Достижения
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: colors.iconColor),
                  SizedBox(width: 8),
                  Text(
                    'Достижения:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Достижения за день
              AchievementCard(
                title: '10,000 шагов',
                description: 'Вы прошли 10,000 шагов за день!',
                icon: Icons.directions_walk,
                color: Colors.green,
                isAchieved: _steps >= 10000,
              ),
              AchievementCard(
                title: '5,000 шагов',
                description: 'Вы прошли 5,000 шагов за день!',
                icon: Icons.directions_walk,
                color: Colors.blue,
                isAchieved: _steps >= 5000,
              ),
              AchievementCard(
                title: '1,000 шагов',
                description: 'Вы прошли 1,000 шагов за день!',
                icon: Icons.directions_walk,
                color: Colors.orange,
                isAchieved: _steps >= 1000,
              ),
              // Достижения за неделю
              AchievementCard(
                title: '70,000 шагов',
                description: 'Вы прошли 70,000 шагов за неделю!',
                icon: Icons.directions_walk,
                color: Colors.purple,
                isAchieved: _weeklySteps.reduce((a, b) => a + b) >= 70000,
              ),
              AchievementCard(
                title: '50,000 шагов',
                description: 'Вы прошли 50,000 шагов за неделю!',
                icon: Icons.directions_walk,
                color: Colors.indigo,
                isAchieved: _weeklySteps.reduce((a, b) => a + b) >= 50000,
              ),
              AchievementCard(
                title: '30,000 шагов',
                description: 'Вы прошли 30,000 шагов за неделю!',
                icon: Icons.directions_walk,
                color: Colors.teal,
                isAchieved: _weeklySteps.reduce((a, b) => a + b) >= 30000,
              ),
              // Достижения за месяц
              AchievementCard(
                title: '300,000 шагов',
                description: 'Вы прошли 300,000 шагов за месяц!',
                icon: Icons.directions_walk,
                color: Colors.red,
                isAchieved: _monthlySteps >= 300000,
              ),
              AchievementCard(
                title: '200,000 шагов',
                description: 'Вы прошли 200,000 шагов за месяц!',
                icon: Icons.directions_walk,
                color: Colors.pink,
                isAchieved: _monthlySteps >= 200000,
              ),
              AchievementCard(
                title: '100,000 шагов',
                description: 'Вы прошли 100,000 шагов за месяц!',
                icon: Icons.directions_walk,
                color: Colors.amber,
                isAchieved: _monthlySteps >= 100000,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAchieved;

  const AchievementCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isAchieved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: isAchieved ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isAchieved ? color : Colors.grey,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAchieved ? color : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isAchieved ? color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final int y;
}
