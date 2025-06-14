// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'targets.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE targets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        golongan TEXT NOT NULL,
        parameter TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        target TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Cek apakah kolom userId sudah ada
      try {
        await db.execute('ALTER TABLE targets ADD COLUMN userId TEXT DEFAULT "unknown_user"');
        print('Kolom userId berhasil ditambahkan');
      } catch (e) {
        print('Error menambahkan kolom userId atau kolom sudah ada: $e');
        // Jika kolom sudah ada, kita abaikan error ini
      }
      
      // Update semua record yang memiliki userId null atau default
      await db.rawUpdate(
        'UPDATE targets SET userId = ? WHERE userId IS NULL OR userId = "unknown_user"', 
        ['default_user_id']
      );
    }
  }

  // Insert target
  Future<int> insertTarget(Map<String, dynamic> target) async {
    final db = await database;
    return await db.insert('targets', target);
  }

  // Get all targets for a specific user
  Future<List<Map<String, dynamic>>> getTargetsByUser(String userId) async {
    final db = await database;
    
    // Cek apakah kolom userId ada di tabel
    List<Map<String, dynamic>> tableInfo = await db.rawQuery("PRAGMA table_info(targets)");
    bool hasUserIdColumn = tableInfo.any((column) => column['name'] == 'userId');
    
    if (!hasUserIdColumn) {
      // Jika kolom userId tidak ada, kembalikan semua data (fallback untuk kompatibilitas)
      print('Kolom userId tidak ditemukan, mengembalikan semua data');
      return await db.query('targets', orderBy: 'createdAt DESC');
    }
    
    return await db.query(
      'targets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  // Update target
  Future<int> updateTarget(int id, Map<String, dynamic> target) async {
    final db = await database;
    return await db.update(
      'targets',
      target,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete target
  Future<int> deleteTarget(int id, String userId) async {
    final db = await database;
    
    // Cek apakah kolom userId ada di tabel
    List<Map<String, dynamic>> tableInfo = await db.rawQuery("PRAGMA table_info(targets)");
    bool hasUserIdColumn = tableInfo.any((column) => column['name'] == 'userId');
    
    if (!hasUserIdColumn) {
      // Jika kolom userId tidak ada, hapus berdasarkan id saja
      print('Kolom userId tidak ditemukan, menghapus berdasarkan id saja');
      return await db.delete('targets', where: 'id = ?', whereArgs: [id]);
    }
    
    return await db.delete(
      'targets',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Method untuk reset database (untuk testing/debugging)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'targets.db');
    await deleteDatabase(path);
    _database = null;
    print('Database direset');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}