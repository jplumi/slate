import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import 'database_helper.dart';

class TaskStorage {
  static Future<Database> get _db async => DatabaseHelper.instance.database;

  static String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Future<List<Task>> loadTasks(DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: 'date = ? AND isDeleted = 0',
      whereArgs: [_dateStr(date)],
      orderBy: 'sortOrder ASC',
    );
    return rows.map((r) => Task.fromMap(r)).toList();
  }

  static Future<void> saveTasks(DateTime date, List<Task> tasks) async {
    final db = await _db;
    final dateStr = _dateStr(date);
    final nowIso = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'tasks',
        columns: ['id'],
        where: 'date = ? AND isDeleted = 0',
        whereArgs: [dateStr],
      );
      final existingIds = existingRows.map((r) => r['id'] as String).toSet();
      final incomingIds = tasks.map((t) => t.id).toSet();

      for (var i = 0; i < tasks.length; i++) {
        final map = tasks[i].toMap();
        map['date'] = dateStr;
        map['isDirty'] = 1;
        map['updatedAt'] = nowIso;
        await txn.insert('tasks', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final removedIds = existingIds.difference(incomingIds);
      for (final id in removedIds) {
        await txn.update(
          'tasks',
          {'isDeleted': 1, 'isDirty': 1, 'updatedAt': nowIso},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  static Future<Set<String>> getAllDatesWithTasks() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date FROM tasks WHERE isDeleted = 0',
    );
    return rows.map((r) => r['date'] as String).toSet();
  }

  static Future<List<Task>> getUnsyncedTasks() async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: 'isDirty = 1',
      orderBy: 'updatedAt ASC',
    );
    return rows.map((r) => Task.fromMap(r)).toList();
  }
}

