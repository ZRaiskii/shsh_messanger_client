import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/AppColors.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/profile_bloc.dart';

class DatePickerContent extends StatefulWidget {
  final AppColors colors;
  final Profile profile;

  const DatePickerContent({
    required this.colors,
    required this.profile,
    Key? key,
  }) : super(key: key);

  @override
  _DatePickerContentState createState() => _DatePickerContentState();
}

class _DatePickerContentState extends State<DatePickerContent> {
  DateTime? _selectedDate;
  bool _isDateSelected = false;
  bool _isDatePickerShown =
      false; // Флаг для отслеживания, был ли показан DatePicker

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDatePickerShown) {
      _isDatePickerShown =
          true; // Устанавливаем флаг, чтобы DatePicker показывался только один раз
      // Откладываем вызов showDatePicker до завершения текущей фазы построения
      Future.microtask(() => _showDatePicker());
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isDateSelected = true;
    });

    // Задержка перед закрытием диалога (для демонстрации анимации)
    Future.delayed(const Duration(milliseconds: 1000), () {
      final profileBloc = BlocProvider.of<ProfileBloc>(context);
      profileBloc.add(UpdateProfileEvent(UpdateProfileParams(
        userId: widget.profile.id,
        profile: widget.profile.copyWith(dateOfBirth: date),
      )));
      Navigator.of(context).pop();
    });
  }

  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.profile.dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.colors.primaryColor,
              onPrimary: widget.colors.buttonTextColor,
              surface: widget.colors.cardColor,
              onSurface: widget.colors.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      _onDateSelected(pickedDate);
    } else if (mounted) {
      // Если пользователь закрыл DatePicker без выбора, закрываем диалог
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.vertical,
            axisAlignment: -1, // Направление анимации
            child: child,
          ),
        );
      },
      child: _isDateSelected
          ? _buildSelectedDateContent()
          : _buildLoadingContent(),
    );
  }

  Widget _buildLoadingContent() {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: CircularProgressIndicator(
          color: widget.colors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSelectedDateContent() {
    return SizedBox(
      width: double.infinity, // Ширина содержимого
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedDate != null
                ? '${_formatDate(_selectedDate!)}'
                : 'Дата не выбрана',
            style: TextStyle(
              color: widget.colors.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Выбранная дата сохранена',
            style: TextStyle(
              color: widget.colors.textColor.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Форматируем дату в формате "день.месяц.год"
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
