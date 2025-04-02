// lib/features/chat/data/services/chat_service.dart
import 'package:shsh_social/features/chat/domain/entities/message.dart';
import 'package:shsh_social/features/chat/domain/repositories/chat_repository.dart';

class ChatService {
  final ChatRepository repository;

  ChatService(this.repository);

  Future<List<Message>> fetchMessages(String chatId) {
    return repository.fetchMessages(chatId);
  }

  Future<void> sendMessage(String chatId, String recipientId, String content) {
    return repository.sendMessage(chatId, recipientId, content);
  }
}
