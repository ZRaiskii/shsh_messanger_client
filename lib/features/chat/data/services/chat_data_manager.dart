class ChatDataManager {
  static final ChatDataManager _instance = ChatDataManager._internal();

  factory ChatDataManager() {
    return _instance;
  }

  ChatDataManager._internal() {}
}
