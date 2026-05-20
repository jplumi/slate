import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskStorage {
  static const String _prefix = 'tasks_';

  static String _keyForDate(DateTime date) {
    return '$_prefix${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<List<Task>> loadTasks(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForDate(date);
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveTasks(DateTime date, List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForDate(date);
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  /// Returns a set of date strings (yyyy-MM-dd) that have at least one task
  static Future<Set<String>> getAllDatesWithTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    return keys.map((k) => k.substring(_prefix.length)).toSet();
  }
}
