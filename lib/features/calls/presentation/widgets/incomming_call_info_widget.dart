import 'package:flutter/material.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';
import 'pulsating_avatart_widget.dart';

class IncomingCallInfo extends StatelessWidget {
  final String username;
  final bool isVideoCall;
  final String? avatarUrl;

  const IncomingCallInfo({
    required this.username,
    required this.isVideoCall,
    this.avatarUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulsatingAvatar(
          size: 150,
          avatarUrl: avatarUrl,
        ),
        const SizedBox(height: 32),
        Text(username,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            )),
        const SizedBox(height: 16),
        Text(
          isVideoCall ? 'Видеозвонок' : 'Звонок',
          style: TextStyle(
            fontSize: 18,
            color: colors.hintColor,
          ),
        ),
      ],
    );
  }
}
