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
    String path = join(await getDatabasesPath(), 'secret_agent_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agent_id INTEGER,
        text TEXT,
        is_user INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE agents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        model_name TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations yet.
  }

  Future<int> insertMessage(int agentId, String message, bool isUser) async {
    final db = await database;
    return await db.insert('messages', {
      'agent_id': agentId,
      'text': message,
      'is_user': isUser ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages(int agentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'agent_id = ?',
      whereArgs: [agentId],
    );
    return maps;
  }

  Future<void> clearMessages(int agentId) async {
    final db = await database;
    await db.delete('messages', where: 'agent_id = ?', whereArgs: [agentId]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('agents');
  }

  // Agent related methods
  Future<int> insertAgent(Map<String, dynamic> agent) async {
    final db = await database;
    return await db.insert(
      'agents',
      agent,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    return await db.delete('agents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAgents() async {
    final db = await database;
    await db.delete('agents');
  }

  Future<List<String>> getDistinctModelNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'agents',
      distinct: true,
      columns: ['model_name'],
    );
    return maps.map((map) => map['model_name'] as String).toList();
  }
}