// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shsh_social/features/chat/data/datasources/chat_local_datasource.dart';
// import 'package:shsh_social/features/chat/data/datasources/chat_remote_datasource.dart';
// import 'package:shsh_social/features/chat/data/repositories/chat_repository_impl.dart';
// import 'package:shsh_social/features/chat/data/services/stomp_client.dart';
// import 'package:shsh_social/features/chat/domain/usecases/fetch_messages_usecase.dart';
// import 'package:shsh_social/features/chat/domain/usecases/send_message_usecase.dart';
// import 'package:shsh_social/features/chat/presentation/bloc/chat_bloc.dart';
// import 'package:http/http.dart' as http;

// class ChatBlocFactory {
//   static Future<ChatBloc> create(
//       String userId, String chatId, BuildContext context) async {
//     try {
//       final sharedPreferences = await SharedPreferences.getInstance();
//       print("SharedPreferences instance created");
//       return ChatBloc(
//         fetchMessagesUseCase: FetchMessagesUseCase(
//           ChatRepositoryImpl(
//             localDataSource: ChatLocalDataSourceImpl(
//               sharedPreferences: sharedPreferences,
//             ),
//             remoteDataSource: ChatRemoteDataSourceImpl(
//               client: http.Client(),
//               webSocketClientService: WebSocketClientService.getInstance(
//                 userId: userId,
//                 chatId: chatId,
//                 context: context,
//               ),
//             ),
//           ),
//         ),
//         sendMessageUseCase: SendMessageUseCase(
//           ChatRepositoryImpl(
//             localDataSource: ChatLocalDataSourceImpl(
//               sharedPreferences: sharedPreferences,
//             ),
//             remoteDataSource: ChatRemoteDataSourceImpl(
//               client: http.Client(),
//               webSocketClientService: WebSocketClientService.getInstance(
//                 userId: userId,
//                 chatId: chatId,
//                 context: context,
//               ),
//             ),
//           ),
//         ),
//         webSocketClientService: WebSocketClientService.getInstance(
//           userId: userId,
//           chatId: chatId,
//           context: context,
//         ),
//       );
//     } catch (e) {
//       print("Error creating ChatBloc: $e");
//       throw e;
//     }
//   }
// }
