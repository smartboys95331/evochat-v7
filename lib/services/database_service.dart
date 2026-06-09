import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'evochat.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            ip TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            senderId TEXT NOT NULL,
            receiverId TEXT NOT NULL,
            text TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE messages ADD COLUMN status INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveMessage(Message msg) async {
    final db = await database;
    await db.insert('messages', msg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMessageStatus(String id, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Message>> getMessages(String peerId, String myId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where:
          '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [myId, peerId, peerId, myId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Message.fromMap(m, m['senderId'] == myId)).toList();
  }

  Future<Message?> getLastMessage(String peerId, String myId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where:
          '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [myId, peerId, peerId, myId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Message.fromMap(maps.first, maps.first['senderId'] == myId);
  }

  Future<void> deleteConversation(String peerId, String myId) async {
    final db = await database;
    await db.delete(
      'messages',
      where:
          '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [myId, peerId, peerId, myId],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('users');
  }
}
