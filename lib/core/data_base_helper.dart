import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../features/chat/domain/entities/message.dart';
import '../features/main/domain/entities/chat.dart';
import '../features/mini_apps/presentation/widgets/custom_calendar_page.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      late var dbPath;
      if (Platform.isWindows) {
        dbPath =
            join(Platform.environment['APPDATA']!, 'shsh', 'database4.sqlite');
      } else {
        dbPath = await getDatabasesPath();
      }
      final path = join(dbPath, 'shsh_local12.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE chats (
      id TEXT PRIMARY KEY,
      user1Id TEXT,
      user2Id TEXT,
      createdAt TEXT,
      username TEXT,
      email TEXT,
      descriptionOfProfile TEXT,
      status TEXT,
      lastMessage TEXT,
      lastMessageTimestamp INTEGER,
      notRead INTEGER,
      lastSequence INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE messages (
      messageId TEXT PRIMARY KEY, -- Используем messageId вместо id
      chatId TEXT,
      senderId TEXT,
      recipientId TEXT,
      content TEXT,
      timestamp INTEGER,
      parentMessageId TEXT,
      isEdited INTEGER,
      editedAt INTEGER,
      status TEXT,
      deliveredAt INTEGER,
      readAt INTEGER,
      FOREIGN KEY (chatId) REFERENCES chats (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE profiles (
      id TEXT PRIMARY KEY,
      username TEXT,
      email TEXT,
      dateOfBirth TEXT,
      descriptionOfProfile TEXT,
      registrationDate TEXT,
      lastUpdated TEXT,
      gender TEXT,
      avatarUrl TEXT,
      chatWallpaperUrl TEXT,
      premiumExpiresAt TEXT,
      nicknameEmoji TEXT,
      active INTEGER,
      shshDeveloper INTEGER,
      verifiedEmail INTEGER,
      premium INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT, 
      title TEXT,
      description TEXT, 
      time TEXT 
    )
  ''');

    await db.execute('''
    CREATE TABLE steps (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT,
      steps INTEGER
    )
  ''');
  }

  Map<String, dynamic> parseKeyValueString(String keyValueString) {
    final map = <String, dynamic>{};
    final keyValuePairs = keyValueString.split(', ');
    for (final pair in keyValuePairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        map[keyValue[0]] = keyValue[1];
      }
    }
    return map;
  }

  Future<void> insertChat(Chat chat) async {
    final db = await database;
    await db.insert(
      'chats',
      chat.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Chat?> getChatByUserIds(String userId1, String userId2) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: '(user1Id = ? AND user2Id = ?) OR (user1Id = ? AND user2Id = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      return Chat(
        id: map['id'] ?? "",
        user1Id: map['user1Id'] ?? "",
        user2Id: map['user2Id'] ?? "",
        createdAt: map['createdAt'] ?? "",
        username: map['username'] ?? "",
        email: map['email'] ?? "",
        descriptionOfProfile: map['descriptionOfProfile'] ?? "",
        status: map['status'] ?? "",
        notRead: map['notRead'] ?? 0,
        lastSequence: map['lastSequence'] ?? 0,
      );
    }
    return null;
  }

  Future<List<Chat>> getChats() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('chats');
      return maps.map((map) {
        return Chat(
          id: map['id'] ?? "",
          user1Id: map['user1Id'] ?? "",
          user2Id: map['user2Id'] ?? "",
          createdAt: map['createdAt'] ?? "",
          username: map['username'] ?? "",
          email: map['email'] ?? "",
          descriptionOfProfile: map['descriptionOfProfile'] ?? "",
          status: map['status'] ?? "",
          notRead: map['notRead'] ?? 0,
          lastSequence: map['lastSequence'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<void> updateChat(Chat chat) async {
    final db = await database;
    try {
      int updatedCount = await db.update(
        'chats',
        chat.toJson(),
        where: 'id = ?',
        whereArgs: [chat.id],
      );
    } catch (e) {
      print("Error updating chat: $e");
    }
  }

  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await deleteMessagesByChatId(chatId);
    await db.delete(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<Chat?> getChatById(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      return Chat(
        id: map['id'] ?? "",
        user1Id: map['user1Id'] ?? "",
        user2Id: map['user2Id'] ?? "",
        createdAt: map['createdAt'] ?? "",
        username: map['username'] ?? "",
        email: map['email'] ?? "",
        descriptionOfProfile: map['descriptionOfProfile'] ?? "",
        status: map['status'] ?? "",
        notRead: map['notRead'] ?? 0,
        lastSequence: map['lastSequence'] ?? 0,
      );
    } else {
      return null;
    }
  }

  Future<Message?> getLastMessageForChat(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Message.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertMessage(Message message) async {
    final db = await database;
    final messageData = {
      ...message.toJson(),
      'isEdited': message.isEdited ?? false ? 1 : 0,
    };
    await db.insert(
      'messages',
      messageData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Message>> getMessages(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) {
      return Message.fromJson(maps[i]);
    });
  }

  Future<void> updateMessage(Message message, {bool? isEdited}) async {
    final db = await database;
    if (isEdited != null) {
      message.isEdited = isEdited;
    }
    final messageData = {
      ...message.toJson(),
      'isEdited': message.isEdited ?? false ? 1 : 0,
    };
    await db.update(
      'messages',
      messageData,
      where: 'messageId = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessagesByChatId(String chatId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> insertProfile(Map<String, dynamic> profile) async {
    final db = await database;

    final existingProfile = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [profile['id']],
    );

    if (existingProfile.isNotEmpty) {
      return;
    }

    final Map<String, dynamic> profileData = {
      ...profile,
      'active': profile['active'] == true ? 1 : 0,
      'shshDeveloper': profile['shshDeveloper'] == true ? 1 : 0,
      'verifiedEmail': profile['verifiedEmail'] == true ? 1 : 0,
      'premium': profile['premium'] == true ? 1 : 0,
    };

    await db.insert(
      'profiles',
      profileData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('Запись успешно добавлена');
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      final profile = maps.first;

      // Преобразуем int в bool
      return {
        ...profile,
        'active': profile['active'] == 1,
        'shshDeveloper': profile['shshDeveloper'] == 1,
        'verifiedEmail': profile['verifiedEmail'] == 1,
        'premium': profile['premium'] == 1,
      };
    }
    return null;
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile,
      where: 'id = ?',
      whereArgs: [profile['id']],
    );
  }

  Future<void> deleteProfile(String userId) async {
    final db = await database;
    await db.delete(
      'profiles',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Вставляет событие в базу данных
  Future<void> insertEvent(Event event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Обновляет событие в базе данных
  Future<void> updateEvent(Event event) async {
    final db = await database;
    await db.update(
      'events',
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Удаляет событие из базы данных
  Future<void> deleteEvent(int eventId) async {
    final db = await database;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  /// Получает все события для указанной даты
  Future<List<Event>> getEventsForDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  /// Получает все события из базы данных
  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  Future<void> insertStepCount(String date, int steps) async {
    final db = await database;
    final existingStepCount = await db.query(
      'steps',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (existingStepCount.isNotEmpty) {
      await db.update(
        'steps',
        {'steps': steps},
        where: 'date = ?',
        whereArgs: [date],
      );
    } else {
      await db.insert(
        'steps',
        {'date': date, 'steps': steps},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<int> getStepCountForDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'steps',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return maps.first['steps'] as int;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStepCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'steps',
      orderBy: 'date DESC',
      limit: 7,
    );
    return maps;
  }

  Future<List<Map<String, dynamic>>> getMonthlyStepCounts() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth =
        DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'steps',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        DateFormat('yyyy-MM-dd').format(startOfMonth),
        DateFormat('yyyy-MM-dd').format(endOfMonth),
      ],
    );

    return maps;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('DELETE FROM chats');
      await txn.execute('DELETE FROM messages');
      await txn.execute('DELETE FROM profiles');
      await txn.execute('DELETE FROM events');
      await txn.execute('DELETE FROM steps');
    });
  }
}
