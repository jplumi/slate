import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import 'database_helper.dart';

class TaskStorage {
  static Future<Database> get _db async => DatabaseHelper.instance.database;

  static const String _lastSyncKey = 'last_sync_time';

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

  static Future<void> saveTask(Task task) async {
    final db = await _db;
    final map = task.toMap();
    map['date'] = _dateStr(task.date);
    map['isDirty'] = 1;
    map['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    await db.insert('tasks', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    final db = await _db;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      for (final task in tasks) {
        final map = task.toMap();
        map['date'] = _dateStr(task.date);
        map['isDirty'] = 1;
        map['updatedAt'] = nowIso;
        await txn.insert('tasks', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<void> deleteTask(String id) async {
    final db = await _db;
    await db.update(
      'tasks',
      {
        'isDeleted': 1,
        'isDirty': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteTasks(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      for (final id in ids) {
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

  static Future<void> markSynced(String id) async {
    final db = await _db;
    await db.update(
      'tasks',
      {'isDirty': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> hardDeleteTask(String id) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final time = prefs.getInt(_lastSyncKey);
    return time != null ? DateTime.fromMillisecondsSinceEpoch(time) : null;
  }

  static Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  static Future<void> mergeRemoteTask(Task task) async {
    final db = await _db;

    final existingRows = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [task.id],
    );

    if (existingRows.isNotEmpty) {
      final localUpdatedAt =
          DateTime.parse(existingRows.first['updatedAt'] as String);
      if (!task.updatedAt.isAfter(localUpdatedAt)) {
        // Local copy is newer or equal; nothing to do.
        return;
      }
    }

    final map = task.toMap();
    map['isDirty'] = 0;
    map['date'] = _dateStr(task.date);
    await db.insert(
      'tasks',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
