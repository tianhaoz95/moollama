import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_history.db');
    return await openDatabase(
      path,
      version: 2, // Increment version to trigger onCreate/onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade for schema changes
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE agents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE agents(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        )
      ''');
    }
  }

  Future<int> insertMessage(String message) async {
    final db = await database;
    return await db.insert('messages', {
      'text': message,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages');
    return List.generate(maps.length, (i) {
      return maps[i]['text'];
    });
  }

  Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  // Agent related methods
  Future<int> insertAgent(Map<String, dynamic> agent) async {
    final db = await database;
    return await db.insert('agents', agent, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    final db = await database;
    return await db.query('agents');
  }

  Future<int> updateAgent(Map<String, dynamic> agent) async {
    final db = await database;
    return await db.update(
      'agents',
      agent,
      where: 'id = ?',
      whereArgs: [agent['id']],
    );
  }

  Future<int> deleteAgent(int id) async {
    final db = await database;
    return await db.delete(
      'agents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAgents() async {
    final db = await database;
    await db.delete('agents');
  }
}