import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../../../core/utils/AppColors.dart';
import '../../data/calling_notification_manager.dart';
import '../widgets/call_action_button_widget.dart';
import '../widgets/call_action_panel_widget.dart';
import '../widgets/call_status_widget.dart';
import '../widgets/incomming_call_info_widget.dart';
import 'call_page.dart';

class IncomingCallPage extends StatefulWidget {
  final String username;
  final bool isVideoCall;
  final String? avatarUrl;

  const IncomingCallPage({
    required this.username,
    required this.isVideoCall,
    this.avatarUrl,
    super.key,
  });

  @override
  _IncomingCallPageState createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  late CallingNotificationManager _notificationManager;

  @override
  void initState() {
    super.initState();
    _notificationManager = CallingNotificationManager(
      onAnswerCall: _acceptCall,
      onDeclineCall: _declineCall,
    );
    _notificationManager.init();
    _showNotification();
    _startRingtoneAndVibration();
  }

  @override
  void dispose() {
    _stopRingtoneAndVibration();
    _notificationManager.cancelNotification();
    super.dispose();
  }

  void _showNotification() {
    String title = 'Звонок от ${widget.username}';
    List<String> actions = ['Ответить', 'Сбросить'];

    _notificationManager.showCallNotification(
      title: title,
      body: '',
      actions: actions,
    );
  }

  Future<void> _startRingtoneAndVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [1000, 1000], repeat: 0);
    }

    try {} catch (e) {
      print('Error playing ringtone: $e');
    }
  }

  void _stopRingtoneAndVibration() {
    Vibration.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.light();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: IncomingCallInfo(
                username: widget.username,
                isVideoCall: widget.isVideoCall,
                avatarUrl: widget.avatarUrl,
              ),
            ),
          ),
          CallActionPanel(
            actions: [
              CallActionButton(
                icon: Icons.call_end,
                onPressed: () {
                  _stopRingtoneAndVibration();
                  _declineCall();
                },
                color: colors.errorColor,
              ),
              CallActionButton(
                icon: Icons.call,
                onPressed: () {
                  _stopRingtoneAndVibration();
                  _acceptCall();
                },
                color: colors.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _declineCall() {
    Navigator.of(context).pop(false);
  }

  void _acceptCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          username: widget.username,
          avatarUrl: widget.avatarUrl,
          status: CallStatus.connecting,
          fromCall: true,
        ),
      ),
    );
  }
}
