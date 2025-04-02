part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class FetchMessagesEvent extends ChatEvent {
  final FetchMessagesParams params;

  const FetchMessagesEvent(this.params);

  @override
  List<Object> get props => [params];
}

class SendMessageEvent extends ChatEvent {
  final SendMessageParams params;

  const SendMessageEvent(this.params);

  @override
  List<Object> get props => [params];
}

class NewMessageReceivedEvent extends ChatEvent {
  final String chatId;

  const NewMessageReceivedEvent(this.chatId);

  @override
  List<Object> get props => [chatId];
}
