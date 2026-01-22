import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';

class StatsRepository {
  final _db = AppDatabase.instance;

  Future<void> upsertDailyStats(
      String dayKey, // YYYY-MM-DD
      List<Map<String, Object?>> rows,
      ) async {
    final total = rows.length;
    final completed = rows.where((r) => (r['is_completed'] as int) == 1).length;

    final high = rows.where((r) => (r['priority'] as int) == 3).length;
    final medium = rows.where((r) => (r['priority'] as int) == 2).length;
    final low = rows.where((r) => (r['priority'] as int) == 1).length;

    final catCount = <String, int>{};
    for (final r in rows) {
      final c = (r['category'] as String?) ?? 'Genel';
      catCount[c] = (catCount[c] ?? 0) + 1;
    }

    String? topCategory;
    if (catCount.isNotEmpty) {
      topCategory = catCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final db = await _db.database;
    await db.insert(
      'daily_stats',
      {
        'day': dayKey,
        'total_tasks': total,
        'completed_tasks': completed,
        'high_count': high,
        'medium_count': medium,
        'low_count': low,
        'top_category': topCategory,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> getDailyStats(String dayKey) async {
    final db = await _db.database;
    final result = await db.query(
      'daily_stats',
      where: 'day = ?',
      whereArgs: [dayKey],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<Map<String, Object?>>> getStatsRange(DateTime startInclusive, DateTime endExclusive) async {
    final db = await _db.database;

    String key(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final da = d.day.toString().padLeft(2, '0');
      return '$y-$m-$da';
    }

    final keys = <String>[];
    var cur = DateTime(startInclusive.year, startInclusive.month, startInclusive.day);
    final end = DateTime(endExclusive.year, endExclusive.month, endExclusive.day);
    while (cur.isBefore(end)) {
      keys.add(key(cur));
      cur = cur.add(const Duration(days: 1));
    }

    if (keys.isEmpty) return [];

    final placeholders = List.filled(keys.length, '?').join(',');
    return db.query('daily_stats', where: 'day IN ($placeholders)', whereArgs: keys);
  }
}
