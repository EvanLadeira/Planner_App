import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planner.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        start TEXT NOT NULL,
        end TEXT NOT NULL,
        color TEXT DEFAULT '#6C63FF',
        category_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#6C63FF'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS themes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#6366f1',
        parent_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        due TEXT,
        theme_id INTEGER,
        parent_id INTEGER
      )
    ''');
  }

  // ── Events ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT events.*, event_categories.name as category_name
      FROM events
      LEFT JOIN event_categories ON events.category_id = event_categories.id
    ''');
  }

  Future<int> createEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.insert('events', event);
  }

  Future<int> updateEvent(int id, Map<String, dynamic> event) async {
    final db = await database;
    return await db.update('events', event, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ── Event Categories ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEventCategories() async {
    final db = await database;
    return await db.query('event_categories');
  }

  Future<int> createEventCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('event_categories', category);
  }

  Future<int> deleteEventCategory(int id) async {
    final db = await database;
    return await db.delete('event_categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Themes ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getThemes() async {
    final db = await database;
    return await db.query('themes');
  }

  Future<int> createTheme(Map<String, dynamic> theme) async {
    final db = await database;
    return await db.insert('themes', theme);
  }

  Future<int> deleteTheme(int id) async {
    final db = await database;
    return await db.delete('themes', where: 'id = ?', whereArgs: [id]);
  }

  // ── Todos ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTodos() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT todos.*, themes.name as theme_name, themes.color as theme_color
      FROM todos
      LEFT JOIN themes ON todos.theme_id = themes.id
    ''');
  }

  Future<int> createTodo(Map<String, dynamic> todo) async {
    final db = await database;
    return await db.insert('todos', todo);
  }

  Future<int> completeTodo(int id) async {
    final db = await database;
    return await db.update('todos', {'done': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
