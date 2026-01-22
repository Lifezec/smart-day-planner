import '../db/app_database.dart';
import '../models/task.dart';

class TaskRepository {
  final _db = AppDatabase.instance;

  Future<int> insertTask(Task task) async {
    final db = await _db.database;
    return db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksForDay(DateTime day) async {
    final db = await _db.database;

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await db.query(
      'tasks',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'priority DESC, date ASC',
    );

    return rows.map((e) => Task.fromMap(e)).toList();
  }

  Future<List<Map<String, Object?>>> getTaskRowsForDay(DateTime day) async {
    final db = await _db.database;

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return db.query(
      'tasks',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<int> updateTask(Task task) async {
    final db = await _db.database;
    return db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await _db.database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
