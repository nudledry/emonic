import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<String> get fullPath async {
    const String databaseName = 'emonic.db';
    final String path = await getDatabasesPath();
    return join(path, databaseName);
  }

  Future<Database> _initDatabase() async {
    final String path = await fullPath;
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE targets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL, -- Tambahkan kolom userId
        golongan TEXT NOT NULL,
        parameter TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        target INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertTarget(Map<String, dynamic> target) async {
    final db = await database;
    return await db.insert('targets', target);
  }

  Future<List<Map<String, dynamic>>> getTargetsByUserId(String userId) async {
    final db = await database;
    return await db.query(
      'targets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  // Fungsi untuk update target (jika diperlukan)
  Future<int> updateTarget(Map<String, dynamic> target) async {
    final db = await database;
    return await db.update(
      'targets',
      target,
      where: 'id = ?',
      whereArgs: [target['id']],
    );
  }

  // Fungsi untuk delete target (jika diperlukan)
  Future<int> deleteTarget(int id) async {
    final db = await database;
    return await db.delete(
      'targets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}