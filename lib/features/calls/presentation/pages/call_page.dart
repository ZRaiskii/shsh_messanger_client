import 'package:flutter/material.dart';
import '../../../../core/utils/AppColors.dart';
import '../../data/calling_notification_manager.dart';
import '../widgets/call_action_button_widget.dart';
import '../widgets/call_action_panel_widget.dart';
import '../widgets/call_appbar_widget.dart';
import '../widgets/call_status_widget.dart';
import '../widgets/call_user_info_widget.dart';

class CallPage extends StatefulWidget {
  final String username;
  final CallStatus status;
  final String? avatarUrl;
  final bool fromCall;

  const CallPage({
    required this.username,
    required this.status,
    required this.avatarUrl,
    this.fromCall = false,
    super.key,
  });

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late CallingNotificationManager _notificationManager;

  @override
  void initState() {
    super.initState();
    _notificationManager = CallingNotificationManager(
      onMuteMicrophone: _toggleMute,
      onDeclineCall: _endCall,
    );
    _notificationManager.init();
    _showNotification();
  }

  @override
  void dispose() {
    _notificationManager.cancelNotification();
    super.dispose();
  }

  void _showNotification() {
    String title = 'Звонок с ${widget.username}';
    String body = widget.status.toString().split('.').last;
    List<String> actions = ['Выключить микрофон', 'Сбросить'];

    _notificationManager.showCallNotification(
      title: title,
      body: body,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.light();

    return Scaffold(
      appBar: CallAppBar(
        title: widget.username,
        onBack: () => _navigateBack(),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: CallUserInfo(
                username: widget.username,
                status: widget.status,
                showDuration: widget.status == CallStatus.connected,
                avatarUrl: widget.avatarUrl,
              ),
            ),
          ),
          CallActionPanel(
            actions: [
              CallActionButton(
                icon: Icons.videocam,
                onPressed: () => _toggleVideo(),
                color: colors.primaryColor,
              ),
              CallActionButton(
                icon: Icons.mic,
                onPressed: () => _toggleMute(),
                color: colors.primaryColor,
              ),
              CallActionButton(
                icon: Icons.call_end,
                onPressed: () => _endCall(),
                color: colors.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleVideo() {
    // Implement video toggle logic
  }

  void _toggleMute() {
    // Implement mute toggle logic
  }

  void _endCall() {
    _navigateBack();
  }

  void _navigateBack() {
    if (widget.fromCall) {
      Navigator.of(context).popUntil(ModalRoute.withName('/main'));
    } else {
      Navigator.of(context).pop();
    }
  }
}
