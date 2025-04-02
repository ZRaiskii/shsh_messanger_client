import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/AppColors.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/profile_bloc.dart';

class DescriptionPickerContent extends StatefulWidget {
  final AppColors colors;
  final Profile profile;

  const DescriptionPickerContent({
    required this.colors,
    required this.profile,
    Key? key,
  }) : super(key: key);

  @override
  _DescriptionPickerContentState createState() =>
      _DescriptionPickerContentState();
}

class _DescriptionPickerContentState extends State<DescriptionPickerContent> {
  late TextEditingController _descriptionController;
  bool _isDescriptionSelected = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.profile.descriptionOfProfile);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDescriptionSaved(String description) {
    setState(() {
      _isDescriptionSelected = true;
    });

    // Задержка перед закрытием диалога (для демонстрации анимации)
    Future.delayed(const Duration(milliseconds: 1000), () {
      final profileBloc = BlocProvider.of<ProfileBloc>(context);
      profileBloc.add(UpdateProfileEvent(UpdateProfileParams(
        userId: widget.profile.id,
        profile: widget.profile.copyWith(descriptionOfProfile: description),
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
      child: _isDescriptionSelected
          ? _buildSelectedDescriptionContent()
          : _buildDescriptionInputContent(),
    );
  }

  Widget _buildDescriptionInputContent() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'О себе (необязательно)',
            style: TextStyle(
              color: widget.colors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 200, // Ограничение на количество символов
            decoration: InputDecoration(
              hintText: 'Расскажите о себе...',
              hintStyle:
                  TextStyle(color: widget.colors.textColor.withOpacity(0.5)),
              labelText: 'Описание профиля',
              labelStyle: TextStyle(color: widget.colors.textColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: widget.colors.cardColor.withOpacity(0.1),
            ),
            style: TextStyle(color: widget.colors.textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final newDescription = _descriptionController.text.trim();
              if (newDescription.isNotEmpty) {
                _onDescriptionSaved(newDescription);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Сохранить',
              style: TextStyle(color: widget.colors.cardColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDescriptionContent() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'Описание не добавлено',
            style: TextStyle(
              color: widget.colors.textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Описание сохранено',
            style: TextStyle(
              color: widget.colors.textColor.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
