import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/AppColors.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/profile_bloc.dart';

class GenderPickerContent extends StatefulWidget {
  final AppColors colors;
  final Profile profile;

  const GenderPickerContent(
      {required this.colors, required this.profile, Key? key})
      : super(key: key);

  @override
  _GenderPickerContentState createState() => _GenderPickerContentState();
}

class _GenderPickerContentState extends State<GenderPickerContent> {
  String? _selectedGender;
  bool _isGenderSelected = false;

  void _onGenderSelected(String gender) {
    setState(() {
      _selectedGender = gender;
      _isGenderSelected = true;
    });

    // Задержка перед закрытием диалога (для демонстрации анимации)
    Future.delayed(const Duration(milliseconds: 1000), () {
      final profileBloc = BlocProvider.of<ProfileBloc>(context);
      profileBloc.add(UpdateProfileEvent(UpdateProfileParams(
        userId: widget.profile.id,
        profile: widget.profile.copyWith(gender: gender),
      )));
      Navigator.of(context).pop();
    });
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
      child: _isGenderSelected
          ? _buildSelectedGenderContent()
          : _buildGenderSelectionContent(),
    );
  }

  Widget _buildGenderSelectionContent() {
    return SizedBox(
      width: double.infinity, // Ширина содержимого
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGenderTile(
            icon: Icons.male,
            label: 'Мужской',
            gender: 'М',
            onTap: () => _onGenderSelected('М'),
          ),
          _buildGenderTile(
            icon: Icons.female,
            label: 'Женский',
            gender: 'Ж',
            onTap: () => _onGenderSelected('Ж'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedGenderContent() {
    return SizedBox(
      width: double.infinity, // Ширина содержимого
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedGender == 'М' ? Icons.male : Icons.female,
            color: widget.colors.textColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedGender == 'М' ? 'Мужской' : 'Женский',
            style: TextStyle(
              color: widget.colors.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Выбранный пол сохранен',
            style: TextStyle(
              color: widget.colors.textColor.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderTile({
    required IconData icon,
    required String label,
    required String gender,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: widget.colors.textColor, size: 32),
      title: Text(
        label,
        style: TextStyle(color: widget.colors.textColor, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
