import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';
import 'call_status_widget.dart';
import 'user_avatar_widget.dart';

class CallUserInfo extends StatefulWidget {
  final String username;
  final CallStatus status;
  final bool showDuration;
  final String? avatarUrl;

  const CallUserInfo({
    required this.username,
    required this.status,
    this.showDuration = false,
    this.avatarUrl,
    super.key,
  });

  @override
  _CallUserInfoState createState() => _CallUserInfoState();
}

class _CallUserInfoState extends State<CallUserInfo> {
  String _dots = '';
  late Timer _timer;

  final Map<CallStatus, String> _statusTranslations = {
    CallStatus.connecting: 'Соединение',
    CallStatus.ringing: 'Звонок',
    CallStatus.connected: '',
    CallStatus.ended: 'Завершено',
    CallStatus.disconnected: 'Отключено',
  };

  @override
  void initState() {
    super.initState();
    _startDotAnimation();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startDotAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _dots = _dots.length < 3 ? _dots + '.' : '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(
          size: 120,
          avatarUrl: widget.avatarUrl,
        ),
        const SizedBox(height: 24),
        Text(widget.username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            )),
        const SizedBox(height: 8),
        _buildStatusIndicator(colors),
        if (widget.showDuration) _buildCallDuration(),
      ],
    );
  }

  Widget _buildStatusIndicator(AppColors colors) {
    String statusText = _statusTranslations[widget.status] ?? '';
    if (widget.status != CallStatus.connected) {
      statusText += _dots;
    }

    return Text(
      statusText,
      style: TextStyle(
        color: colors.hintColor,
        fontSize: 16,
      ),
    );
  }

  Widget _buildCallDuration() {
    final colors = AppColors.light();
    return StreamBuilder<Duration>(
      stream: _callDurationStream(),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return Text(
          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 16,
            color: colors.primaryColor,
          ),
        );
      },
    );
  }

  Stream<Duration> _callDurationStream() async* {
    Duration duration = Duration.zero;
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      duration += Duration(seconds: 1);
      yield duration;
    }
  }
}
