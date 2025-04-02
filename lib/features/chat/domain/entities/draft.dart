import 'dart:convert';

import 'message.dart';

class Draft {
  final String text;
  final Message? replyMessage;

  Draft({required this.text, this.replyMessage});

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      text: json['text'] ?? '',
      replyMessage: json['replyMessage'] != null
          ? Message.fromJson(json['replyMessage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'replyMessage': replyMessage?.toJson(),
    };
  }
}
