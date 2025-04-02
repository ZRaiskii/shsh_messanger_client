import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SendMessageParams extends Equatable {
  final String chatId;
  final String recipientId;
  final String content;

  const SendMessageParams({
    required this.chatId,
    required this.recipientId,
    required this.content,
  });

  @override
  List<Object> get props => [chatId, recipientId, content];
}

class SendMessageUseCase implements UseCase<void, SendMessageParams> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) async {
    try {
      await repository.sendMessage(
          params.chatId, params.recipientId, params.content);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
