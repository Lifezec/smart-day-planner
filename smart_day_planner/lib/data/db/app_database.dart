import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static const _dbName = 'smartday.db';
  static const _dbVersion = 4; // Sürüm yükseltildi (Puan sistemi için)

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
          await db.execute('CREATE TABLE daily_stats (day TEXT PRIMARY KEY, total_tasks INTEGER NOT NULL, completed_tasks INTEGER NOT NULL, high_count INTEGER NOT NULL, medium_count INTEGER NOT NULL, low_count INTEGER NOT NULL, top_category TEXT)');
          await db.insert('categories', {'name': 'Genel'});
          await db.insert('categories', {'name': 'Okul'});
          await db.insert('categories', {'name': 'İş'});
          await db.insert('categories', {'name': 'Kişisel'});
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL,
              full_name TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          // ✅ Puan ve Seviye Sistemi için kolonlar eklendi
          try {
            await db.execute('ALTER TABLE users ADD COLUMN points INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE users ADD COLUMN completed_count INTEGER DEFAULT 0');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        priority INTEGER NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        day TEXT PRIMARY KEY,
        total_tasks INTEGER NOT NULL,
        completed_tasks INTEGER NOT NULL,
        high_count INTEGER NOT NULL,
        medium_count INTEGER NOT NULL,
        low_count INTEGER NOT NULL,
        top_category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT,
        points INTEGER DEFAULT 0,
        completed_count INTEGER DEFAULT 0
      )
    ''');

    await db.insert('categories', {'name': 'Genel'});
    await db.insert('categories', {'name': 'Okul'});
    await db.insert('categories', {'name': 'İş'});
    await db.insert('categories', {'name': 'Kişisel'});
    
    await db.insert('users', {
      'username': 'admin',
      'password': '123',
      'full_name': 'Akıllı Kullanıcı',
      'points': 0,
      'completed_count': 0
    });
  }
}
