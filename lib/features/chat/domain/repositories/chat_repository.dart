// lib/features/chat/domain/repositories/chat_repository.dart
import 'package:shsh_social/features/chat/domain/entities/message.dart';

abstract class ChatRepository {
  Future<List<Message>> fetchMessages(String chatId);
  Future<void> sendMessage(String chatId, String recipientId, String content);
}
