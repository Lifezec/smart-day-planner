import '../db/app_database.dart';

class CategoryRepository {
  final _db = AppDatabase.instance;

  Future<List<String>> getCategories() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((r) => (r['name'] as String)).toList();
  }

  Future<void> addCategory(String name) async {
    final db = await _db.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await db.insert('categories', {'name': trimmed});
  }
}
