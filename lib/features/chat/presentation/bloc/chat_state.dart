part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatFailure extends ChatState {
  final String message;

  const ChatFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ChatSuccess extends ChatState {
  final List<Message> messages;

  const ChatSuccess(this.messages);

  @override
  List<Object> get props => [messages];
}

class NewMessageReceived extends ChatState {}
