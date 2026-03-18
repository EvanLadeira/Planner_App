import 'database.dart';

final db = DatabaseHelper.instance;

// ── Events ────────────────────────────────────────────────
Future<List<dynamic>> getEvents() async {
  return await db.getEvents();
}

Future<void> createEventFull(String title, String description, String start, String end, String color, {int? categoryId}) async {
  await db.createEvent({
    'title': title,
    'description': description,
    'start': start,
    'end': end,
    'color': color,
    'category_id': categoryId,
  });
}

Future<void> updateEvent(int id, String title, String description, String start, String end, String color, {int? categoryId}) async {
  await db.updateEvent(id, {
    'title': title,
    'description': description,
    'start': start,
    'end': end,
    'color': color,
    'category_id': categoryId,
  });
}

Future<void> deleteEvent(int id) async {
  await db.deleteEvent(id);
}

// ── Event Categories ──────────────────────────────────────
Future<List<dynamic>> getEventCategories() async {
  return await db.getEventCategories();
}

Future<void> createEventCategory(String name, String color) async {
  await db.createEventCategory({'name': name, 'color': color});
}

Future<void> deleteEventCategory(int id) async {
  await db.deleteEventCategory(id);
}

// ── Themes ────────────────────────────────────────────────
Future<List<dynamic>> getThemes() async {
  return await db.getThemes();
}

Future<void> createTheme(String name, String color, {int? parentId}) async {
  await db.createTheme({'name': name, 'color': color, 'parent_id': parentId});
}

Future<void> deleteTheme(int id) async {
  await db.deleteTheme(id);
}

// ── Todos ─────────────────────────────────────────────────
Future<List<dynamic>> getTodos() async {
  return await db.getTodos();
}

Future<void> createTodo(String title, {int? themeId}) async {
  await db.createTodo({'title': title, 'theme_id': themeId});
}

Future<void> completeTodo(int id) async {
  await db.completeTodo(id);
}

Future<void> deleteTodo(int id) async {
  await db.deleteTodo(id);
}

Future<void> createSubTodo(String title, int parentId) async {
  await db.createTodo({'title': title, 'parent_id': parentId});
}