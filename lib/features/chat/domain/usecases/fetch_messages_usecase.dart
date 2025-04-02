// lib/features/chat/domain/usecases/fetch_messages_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shsh_social/core/error/exceptions.dart';
import 'package:shsh_social/core/error/failures.dart';
import 'package:shsh_social/core/usecases/usecase.dart';
import 'package:shsh_social/features/chat/domain/entities/message.dart';
import 'package:shsh_social/features/chat/domain/repositories/chat_repository.dart';

class FetchMessagesParams extends Equatable {
  final String chatId;

  const FetchMessagesParams({
    required this.chatId,
  });

  @override
  List<Object> get props => [chatId];
}

class FetchMessagesUseCase
    implements UseCase<List<Message>, FetchMessagesParams> {
  final ChatRepository repository;

  FetchMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(
      FetchMessagesParams params) async {
    try {
      final messages = await repository.fetchMessages(params.chatId);
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
