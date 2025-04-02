import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/services/stomp_client.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/fetch_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FetchMessagesUseCase fetchMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final WebSocketClientService webSocketClientService;

  ChatBloc({
    required this.fetchMessagesUseCase,
    required this.sendMessageUseCase,
    required this.webSocketClientService,
  }) : super(ChatInitial()) {
    webSocketClientService.connect();

    on<FetchMessagesEvent>((event, emit) async {
      emit(ChatLoading());
      final failureOrMessages = await fetchMessagesUseCase(event.params);
      failureOrMessages.fold(
        (failure) => emit(ChatFailure(failure.message)),
        (messages) {
          emit(ChatSuccess(messages));
        },
      );
    });

    on<SendMessageEvent>((event, emit) async {
      emit(ChatLoading());
      final failureOrVoid = await sendMessageUseCase(event.params);
      failureOrVoid.fold(
        (failure) => emit(ChatFailure(failure.message)),
        (_) {
          print('Message sent successfully');
          add(FetchMessagesEvent(
              FetchMessagesParams(chatId: event.params.recipientId)));
        },
      );
    });

    on<NewMessageReceivedEvent>((event, emit) async {
      print('New message received for chat: ${event.chatId}');
      emit(NewMessageReceived());
    });
  }

  @override
  Future<void> close() {
    // webSocketClientService.disconnect();
    return super.close();
  }
}
