import '../../../../core/error/exceptions.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Message>> fetchMessages(String chatId) async {
    try {
      final remoteMessages = await remoteDataSource.fetchMessages(chatId);
      localDataSource.cacheMessages(remoteMessages);
      return remoteMessages
          .map((messageModel) => Message(
                id: messageModel.id,
                chatId: messageModel.chatId,
                senderId: messageModel.senderId,
                recipientId: messageModel.recipientId, // Новое поле
                content: messageModel.content,
                timestamp: messageModel.timestamp,
                parentMessageId: messageModel.parentMessageId,
                isEdited: messageModel.isEdited, // Новое поле
                editedAt: messageModel.editedAt, // Новое поле
                status: messageModel.status, // Новое поле
                deliveredAt: messageModel.deliveredAt, // Новое поле
                readAt: messageModel.readAt, // Новое поле
              ))
          .toList();
    } on ServerException {
      try {
        final localMessages = await localDataSource.getCachedMessages();
        return localMessages
            .map((messageModel) => Message(
                  id: messageModel.messageId,
                  chatId: messageModel.chatId,
                  senderId: messageModel.senderId,
                  recipientId: messageModel.recipientId, // Новое поле
                  content: messageModel.content,
                  timestamp: messageModel.timestamp,
                  parentMessageId: messageModel.parentMessageId,
                  isEdited: messageModel.isEdited, // Новое поле
                  editedAt: messageModel.editedAt, // Новое поле
                  status: messageModel.status, // Новое поле
                  deliveredAt: messageModel.deliveredAt, // Новое поле
                  readAt: messageModel.readAt, // Новое поле
                ))
            .toList();
      } on CacheException {
        throw CacheException("Чат пуст");
      }
    }
  }

  @override
  Future<void> sendMessage(
      String chatId, String recipientId, String content) async {
    await remoteDataSource.sendMessage(chatId, recipientId, content);
  }
}
