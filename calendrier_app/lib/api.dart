import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://localhost:8000';
// const String baseUrl = 'http://192.168.0.12:8000';

// ── Events ────────────────────────────────────────────────
Future<List<dynamic>> getEvents() async {
  final response = await http.get(Uri.parse('$baseUrl/events'));
  return jsonDecode(response.body);
}

Future<void> createEvent(String title, String description, String start, String end) async {
  await http.post(
    Uri.parse('$baseUrl/events'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'description': description,
      'start': start,
      'end': end,
    }),
  );
}

Future<void> deleteEvent(int id) async {
  await http.delete(Uri.parse('$baseUrl/events/$id'));
}

// ── Themes ────────────────────────────────────────────────
Future<List<dynamic>> getThemes() async {
  final response = await http.get(Uri.parse('$baseUrl/themes'));
  return jsonDecode(response.body);
}

Future<void> createTheme(String name, String color, {int? parentId}) async {
  await http.post(
    Uri.parse('$baseUrl/themes'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'color': color,
      'parent_id': parentId,
    }),
  );
}

Future<void> deleteTheme(int id) async {
  await http.delete(Uri.parse('$baseUrl/themes/$id'));
}

// ── Todos ─────────────────────────────────────────────────
Future<List<dynamic>> getTodos() async {
  final response = await http.get(Uri.parse('$baseUrl/todos'));
  return jsonDecode(response.body);
}

Future<void> createTodo(String title, {int? themeId}) async {
  await http.post(
    Uri.parse('$baseUrl/todos'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'theme_id': themeId,
    }),
  );
}

Future<void> completeTodo(int id) async {
  await http.patch(Uri.parse('$baseUrl/todos/$id/done'));
}

Future<void> deleteTodo(int id) async {
  await http.delete(Uri.parse('$baseUrl/todos/$id'));
}

Future<void> createSubTodo(String title, int parentId) async {
  await http.post(
    Uri.parse('$baseUrl/todos/$parentId/subtodos'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'title': title}),
  );
}

// ── Event Categories ──────────────────────────────────────
Future<List<dynamic>> getEventCategories() async {
  final response = await http.get(Uri.parse('$baseUrl/event-categories'));
  return jsonDecode(response.body);
}

Future<void> createEventCategory(String name, String color) async {
  await http.post(
    Uri.parse('$baseUrl/event-categories'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name, 'color': color}),
  );
}

Future<void> deleteEventCategory(int id) async {
  await http.delete(Uri.parse('$baseUrl/event-categories/$id'));
}

// ── Events (mise à jour) ──────────────────────────────────
Future<void> createEventFull(String title, String description, String start, String end, String color, {int? categoryId}) async {
  await http.post(
    Uri.parse('$baseUrl/events'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'description': description,
      'start': start,
      'end': end,
      'color': color,
      'category_id': categoryId,
    }),
  );
}

Future<void> updateEvent(int id, String title, String description, String start, String end, String color, {int? categoryId}) async {
  await http.put(
    Uri.parse('$baseUrl/events/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'description': description,
      'start': start,
      'end': end,
      'color': color,
      'category_id': categoryId,
    }),
  );
}