class Constants {
  static const String baseUrl = 'http://90.156.171.188:8080';
  static const String baseUrl2 = 'http://90.156.171.188:8089';

  // Auth Endpoints
  static const String registrationEndpoint = '/auth/registration';
  static const String loginEndpoint = '/auth/login';
  static const String refreshTokenEndpoint = '/auth/refresh-token';

  // WebSocket Gateway URL
  static const String webSocketGatewayUrl = 'ws://192.168.0.104:8080/ws';

  // WebSocket Headers
  static const String authorizationHeader = 'Authorization';

  // WebSocket Topics
  static const String userQueueTopic = '/user/';
  static const String sendMessageTopic = '/app/send';
  static const String sendPhotoMessageTopic = '/app/send/photo';

  // Chat Endpoints
  static const String createOneToOneChatEndpoint = '/chats/createOneToOneChat';
  static const String getAllChatsEndpoint = '/chats/allChats';

  // Message Endpoints
  static const String getAllMessagesInChatEndpoint =
      '/messages/getAllMessagesInChat';
  static const String updateMessageStatusDeliveredEndpoint =
      '/messages/status/delivered';
  static const String updateMessageStatusReadEndpoint = '/messages/status/read';

  // Photo Endpoints
  static const String uploadPhotoEndpoint = '/cs/api/photos/upload/';
  static const String downloadPhotoEndpoint = '/cs/api/photos/download/';
  static const String deletePhotoEndpoint = '/cs/api/photos/delete/';

  // User Endpoints
  static const String searchUsersEndpoint = '/ups/api/search';
  static const String getIdByUsernameEndpoint = '/ups/api/id-by-username';

  // Profile Endpoints
  static const String uploadAvatarEndpoint = '/photos/upload-avatar/';
  static const String deleteAvatarEndpoint = '/photos/delete-avatar/';
  static const String getUserStatusEndpoint = '/ups/api/users/';
  static const String getUsersStatusesEndpoint = '/ups/api/users/statuses';
  static const String getUserProfileEndpoint = '/user/profile/';
  static const String checkPremiumStatusEndpoint = '/user/profile/';
  static const String updateUserProfileEndpoint = '/user/profile/update';
  static const String getUserProfileForChatEndpoint = '/user/profile/for-chat/';
  static const String updateUserEmojiEndpoint = '/user/profile/';
  static const String updateUserPremiumEndpoint = '/user/profile/';
}
